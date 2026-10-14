# 03 · Control Groups (cgroups)

> **Goal**: Understand cgroups — the kernel mechanism for resource accounting, limits, and process-group control.

From Wikipedia: *cgroups is a Linux kernel feature that limits, accounts for, and isolates the resource usage (CPU, memory, disk I/O, network, etc.) of a collection of processes.* Engineers at Google started work on it in 2006 (originally called "process containers"); it merged into the kernel in 2.6.24 (2008).

Namespaces are the other Linux kernel feature for containers; they isolate and virtualize system resources for a collection of processes. They were inspired by Plan 9 (which takes the same concept much further).

---

## cgroup v1 vs v2

There have been **two cgroups layouts** in the kernel's history:

| | v1 (legacy) | v2 (current) |
|--|-------------|--------------|
| Hierarchies | one per controller | **one unified tree** |
| Mounted at | `/sys/fs/cgroup/<controller>/` | `/sys/fs/cgroup/` |
| Controller interfaces | per-controller files | standardized (`*.max`, `*.weight`, ...) |
| Freezer | separate controller | **core feature** — every cgroup can be frozen |
| Delegation to userland | broken/inconsistent | safe via systemd |

Modern distributions ship cgroup **v2 only** (Debian 11+, Ubuntu 22.04+, Fedora 31+). This tutorial uses **v2 exclusively**.

To verify:
```bash
$ stat -fc %T /sys/fs/cgroup
cgroup2fs          # ← v2 root filesystem
```

---

## Exercise — namespaces before cgroups

> ⚠️ Start this as a **non-root** user (the default `vagrant` VM user is perfect). We will escalate later.

```bash
$ id
uid=1000(vagrant) gid=1000(vagrant) groups=1000(vagrant)
```

The `/proc` pseudo-filesystem lets you inspect the namespaces your process currently lives in:

```bash
$ ls -la /proc/self/ns
total 0
dr-x--x--x 2 root root 0 Nov  1 13:07 .
dr-xr-xr-x 9 root root 0 Nov  1 13:07 ..
lrwxrwxrwx 1 root root 0 Nov  1 13:07 cgroup -> cgroup:[4026531835]
lrwxrwxrwx 1 root root 0 Nov  1 13:07 ipc    -> ipc:[4026531839]
lrwxrwxrwx 1 root root 0 Nov  1 13:07 mnt    -> mnt:[4026531840]
lrwxrwxrwx 1 root root 0 Nov  1 13:07 net    -> net:[4026531957]
lrwxrwxrwx 1 root root 0 Nov  1 13:07 pid    -> pid:[4026531836]
lrwxrwxrwx 1 root root 0 Nov  1 13:07 user   -> user:[4026531837]
lrwxrwxrwx 1 root root 0 Nov  1 13:07 uts    -> uts:[4026531838]
```

Each link is a namespace **handle** — the kernel tracks them by inode number. Two processes in the same namespace have the same number. The 8 modern namespace types are: cgroup, ipc, mnt, net, pid, time, user, uts.

### Where do I live in the cgroup tree?

```bash
$ cat /proc/self/cgroup
0::/user.slice/user-1000.slice/session-1.scope
```

Compare with a v1 system (would show 11+ lines like `11:devices:...`, `10:memory:...`). With v2 there is **one single line** — one unified hierarchy, and systemd has already placed you logically under `user.slice/user-1000.slice/session-1.scope`.

### User namespaces — becoming "root" without risk

```bash
$ unshare --map-root-user --user
# id
uid=0(root) gid=0(root) groups=0(root)

# cat /proc/self/uid_map
         0       1000          1
```

Translation: *"uid 0 in this namespace maps to uid 1000 on the host (range=1)."* You are root *here*, but only for resources owned by this namespace. This is how rootless Docker works.

```bash
# ls -la /proc/self/ns | grep user
lrwxrwxrwx 1 root root 0 Nov  1 13:51 user -> user:[4026532135]
# echo $$
11222
```

**Don't exit this shell yet.** Note its PID (here: `11222`).

---

## Exercise — cgroup control (freezer)

Now switch to **another shell** running as *real* root.

>v2 terminology: v1 managed **threads** via a `tasks` file per controller. v2 manages **processes** via `cgroup.procs` — writing a PID adds the whole process at once.

```bash
# id
uid=0(root) gid=0(root) groups=0(root)

# ls /sys/fs/cgroup/
cgroup.controllers            cgroup.threads     io.pressure
cgroup.events                 cgroup.type        io.stat
cgroup.freeze                 cpu.pressure       io.weight
cgroup.max.depth              cpu.stat           memory.pressure
cgroup.max.descendants        cpuset.cpus        memory.stat
cgroup.procs                  cpuset.mems        memory.zswap.current
cgroup.stat                   init.scope         system.slice
cgroup.subtree_control        io.cost.model      user.slice
```

One **single** directory — no per-controller mounts. `cat cgroup.controllers` shows what's available; the directories are systemd's top-level slices.

Create a cgroup and move the unshared shell into it:

```bash
# cd /sys/fs/cgroup
# mkdir test && cd test

# ls
cgroup.controllers            cgroup.procs        cpu.uclamp.max       memory.low
cgroup.events                 cgroup.stat         cpu.uclamp.min       memory.max
cgroup.freeze                 cgroup.subtree_control                memory.min
cgroup.kill                   cgroup.threads      io.max               memory.peak
cgroup.max.depth              cgroup.type         io.stat              memory.pressure
cgroup.max.descendants        cpuset.cpus         io.weight            memory.zswap.max
cgroup.memory.events         cpu.idle            memory.current       pids.current
cgroup.memory.reclaim         cpu.max             memory.events        pids.events
cgroup.memory.zswap...        cpu.pressure        memory.events.local  pids.max
...

# echo 11222 > cgroup.procs
```

Back in the **unshared shell**, verify:

```bash
# cat /proc/self/cgroup
0::/test
```

Now, from the root shell, **freeze the whole cgroup** with one write:

```bash
# echo 1 > /sys/fs/cgroup/test/cgroup.freeze
```

Your unshare shell is **dead-frozen**. The kernel has stopped scheduling every process in `/sys/fs/cgroup/test`.

### Event-driven, not polling

While frozen, inspect the event interface (this is what systemd uses to get notifications):

```bash
# cat /sys/fs/cgroup/test/cgroup.events
populated 1
frozen 1
```

`cgroup.events` is **pollable** — a supervisor can wait for the `frozen`/`populated` fields to change instead of busy-polling.

### Thaw

```bash
# echo 0 > /sys/fs/cgroup/test/cgroup.freeze
```

Your shell wakes up and processes the buffered input — everything you typed while frozen comes through at once.

### Cleanup

```bash
# exit               # leave the unprivileged shell
# rmdir /sys/fs/cgroup/test
```

(Only empty cgroups can be removed.)

---

## Where's the freezer in real containers?

This is exactly how `docker pause` and `docker unpause` work.

```bash
docker pause mycontainer        # → echo 1 > /sys/fs/cgroup/.../cgroup.freeze
docker unpause mycontainer      # → echo 0 > /sys/fs/cgroup/.../cgroup.freeze
```

Kubernetes, containerd, systemd-nspawn — all the same underlying file. The whole "container runtime" world is just **cgroups + namespaces** with an API on top.

---

## Next →

[04 cgroups & namespaces — part 2](04cgroups.md) — apply resource limits and full namespace isolation
