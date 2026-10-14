# 04 · cgroups & namespaces — Part 2

> **Goal**: Apply real resource limits with cgroup v2, and combine them with full namespace isolation (`unshare` + `chroot`).

In [chapter 03](03cgroups.md) we created cgroups, moved processes between them, and froze/thawed a shell. In this chapter we apply **limits** (cpu, memory, pids) and combine them with **new namespaces** via `unshare`.

---

## How cgroup v2 resource control works

All controllers hang off the **single mount** `/sys/fs/cgroup`. Each directory is a cgroup. The files in there come in two kinds:

| File | Purpose |
|------|---------|
| `cgroup.procs` | member processes of this cgroup |
| `cgroup.controllers` | controllers *available* in this directory |
| `cgroup.subtree_control` | which controllers are *enabled* for children |
| `cgroup.freeze` | freeze all processes in this tree |
| `cpu.max` | CPU bandwidth limit |
| `cpu.weight` | relative CPU shares (1–10000) |
| `memory.max` | hard memory cap |
| `pids.max` | max number of PIDs |

Two rules keep the tree sane:

1. **No internal processes** — a cgroup that has processes may not enable controllers for children.
2. **Top-down delegation** — a child can only use a controller if all its ancestors enabled it.

This makes the tree usable without needing `/etc/cgconfig.conf` or per-controller mounts. It also forces you to organize processes so that leaf cgroups are empty — which is what Docker and systemd already do.

---

## Exercise — CLI cgroup management

> Start as **root** in the folder containing the chroot from chapter 02.

```bash
cd /home/vagrant/container101
id
```

First inspect where we live, and what the tree gives us:

```bash
# cat /proc/self/cgroup
0::/user.slice/user-1000.slice/session-1.scope

# cat /sys/fs/cgroup/cgroup.controllers
cpuset cpu io memory hugetlb pids rdma misc
```

Now create a `sandbox` cgroup under root and delegate the controllers we want into it:

```bash
cd /sys/fs/cgroup

# Enable controllers for children of root:
echo "+cpu +memory +io +pids" > cgroup.subtree_control

# Create our playground:
mkdir sandbox

# Check what we can use:
cat sandbox/cgroup.controllers
cpu io memory pids
```

### CPU limit — the single-file API

This sets a hard cap of 100% of one CPU:

```bash
# echo 100000 > sandbox/cpu.max
# cat sandbox/cpu.max
100000 100000

# Move this shell (and its whole tree) into the cgroup:
# echo $$ > sandbox/cgroup.procs
```

### Now enter a full namespaced container

Combine `unshare` with our chroot. This is the *real* "container feel" — new uts (hostname), ipc, pid, and mount namespaces — landed inside our `sandbox` cgroup.

```bash
unshare --mount --uts --ipc --pid --fork chroot container /bin/bash
```

Inside the container:

```bash
bash-5.2# mkdir /proc        # only needed once, on first use of this rootfs
bash-5.2# mount -t proc proc /proc
bash-5.2# cat /proc/self/cgroup
0::/sandbox
```

Only **one** cgroup line in the unified v2 hierarchy.

### Test namespace isolation

```bash
bash-5.2# ps
    PID TTY          TIME CMD
      1 ?        00:00:00 bash
      7 ?        00:00:00 ps

bash-5.2# hostname
container101
bash-5.2# hostname hugabuga
bash-5.2# hostname
hugabuga
```

In another host terminal, confirm the host hostname is untouched:

```bash
# hostname
container101
```

(The container hostname `hugabuga` exists only in its `uts` namespace.)

### Stress — see the CPU cap in action

Inside the container:

```bash
bash-5.2# stress -c 2
```

From another host shell, watch the cgroup accounting:

```bash
# cat /sys/fs/cgroup/sandbox/cpu.stat
usage_usec 5213459
user_usec 5200000
system_usec 13459
nr_periods 105
nr_throttled 96
throttled_usec 9587234
```

`nr_throttled` going up shows the cgroup actively refusing cycles beyond `cpu.max`.

![stress](stress.png)

---

## The native systemd way (recommended on real systems)

Writing into `/sys/fs/cgroup` by hand fights **systemd**, which owns the whole tree and periodically cleans up "foreign" cgroups. The native way on any systemd distribution is `systemd-run`:

```bash
systemd-run --scope --quiet \
  --slice=limit \
  -p CPUQuota=10% -p MemoryMax=200M -p TasksMax=50 \
  --unit=sandbox \
  unshare --mount --uts --ipc --pid --fork --mount-proc chroot container /bin/bash
```

This single command:
1. asks systemd to create a transient scope `sandbox.scope`
2. lets systemd do the `subtree_control` setup
3. maps high-level properties onto `cpu.max`, `memory.max`, `pids.max`
4. cleans the cgroup away when the process exits

While it runs:

```bash
systemctl status sandbox.scope
● sandbox.scope - [systemd-run] ...
   Transient: yes
     Active: active (running)
    Tasks: 1 (limit: 50)
    Memory: 164K (max: 200M, peak: 744K)
     CGroup: /limit.slice/sandbox.scope

cat /sys/fs/cgroup/limit.slice/sandbox.scope/cpu.max
10000 100000              # 10% of one CPU
cat /sys/fs/cgroup/limit.slice/sandbox.scope/memory.max
209715200                 # 200M
```

> **Why can't we do the manual way under `user.slice`?**
> The "no internal processes" rule forbids enabling controllers in a cgroup that already has processes. `systemd-run` sidesteps this by creating a fresh child scope under a slice; that's exactly what Docker/containerd do internally.

When you exit the container, the namespaces are gone and the root environment is untouched.

---

## What's next

The advanced reader can continue with the man page for [`nsenter`](https://man7.org/linux/man-pages/man1/nsenter.1.html) — the tool that lets you *enter* an existing namespace. Try entering the `uts`/`ip`/`pid` namespace of one of your unshare processes.

---

**Next →** [05 Docker images](05docker.md) — build, tag, and publish a container image
