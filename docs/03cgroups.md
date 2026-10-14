# 03 Play with cgroups & namespaces

From Wikipedia: cgroups is a Linux kernel feature that limits, accounts for, and isolates the resource usage (CPU, memory, disk I/O, network, etc.) of a collection of processes.
* Engineers at Google started the work on this feature in 2006 under the name "process containers". The control groups functionality was merged into the Linux kernel mainline in kernel version 2.6.24, which was released in January 2008.

Namespaces are a feature of the Linux kernel that isolates and virtualizes system resources of a collection of processes, they are a fundamental aspect of containers on Linux.
* Linux namespaces were inspired by the more general namespace functionality used heavily throughout Plan 9 from Bell Labs.

>cgroup **v1 vs. v2**: The kernel originally grew one separate hierarchy (mount) per controller — that's cgroup v1. It turned out to be inconsistent and hard to coordinate, so a redesigned **unified hierarchy, cgroup v2**, was declared stable in kernel 4.5 and is the default on all modern distributions (Debian/Ubuntu/Fedora ship v2-only since ~2022). In v2 there is exactly **one** tree mounted at `/sys/fs/cgroup`, all controllers attach to it, and every cgroup exposes the same generic interface files (`cgroup.procs`, `cgroup.freeze`, `cgroup.controllers`, `cgroup.subtree_control`, ...). This tutorial only uses v2; with a v1-only setup you are on your own (see [archived v1 docs](https://www.kernel.org/doc/html/v5.3/admin-guide/cgroup-v1/cgroups.html), run `stat -fc %T /sys/fs/cgroup` — it prints `cgroup2fs` when you are on v2).

### Exercise

Please start the following as a non-root user.
```
$ id
uid=1000(vagrant) gid=1000(vagrant) groups=1000(vagrant)
```

The Linux `/proc` system allows you to inspect namespaces, cgroups and various other tables of your environment. We will now inspect a couple of pointers:
```
$ ls -la /proc/self/ns
total 0
dr-x--x--x 2 root root 0 Mar 13 13:07 .
dr-xr-xr-x 9 root root 0 Mar 13 13:07 ..
lrwxrwxrwx 1 root root 0 Mar 13 13:07 cgroup -> cgroup:[4026531835]
lrwxrwxrwx 1 root root 0 Mar 13 13:07 ipc -> ipc:[4026531839]
lrwxrwxrwx 1 root root 0 Mar 13 13:07 mnt -> mnt:[4026531840]
lrwxrwxrwx 1 root root 0 Mar 13 13:07 net -> net:[4026531957]
lrwxrwxrwx 1 root root 0 Mar 13 13:07 pid -> pid:[4026531836]
lrwxrwxrwx 1 root root 0 Mar 13 13:07 pid_for_children -> pid:[4026531836]
lrwxrwxrwx 1 root root 0 Mar 13 13:07 time -> time:[4026531834]
lrwxrwxrwx 1 root root 0 Mar 13 13:07 time_for_children -> time:[4026531834]
lrwxrwxrwx 1 root root 0 Mar 13 13:07 user -> user:[4026531837]
lrwxrwxrwx 1 root root 0 Mar 13 13:07 uts -> uts:[4026531838]
```
The listing under `/proc/self/ns/<nstype>` shows files with their respective file descriptor that can be used to identify a specific namespace. Simplified, you can think of the number as a pointer to a virtual table in the kernel. Modern kernels have 8 namespace types (`time` was added in kernel 5.6).
```
$ cat /proc/self/cgroup
0::/user.slice/user-1000.slice/session-1.scope
```
Notice how different this looks from old cgroup v1 examples: instead of one line per controller (`11:devices:...`, `10:memory:...`, ...) there is now only a **single** line — one unified v2 hierarchy, with your process sitting in a path that systemd manages (a [session scope](https://systemd.io/CGROUP_DELEGATION/) under your user slice).

```
$ cat /proc/self/uid_map
         0          0 4294967295
```
From the man pages of User Namespaces, with some interpretation: Each line in the uid_map file specifies a 1-to-1 mapping of a range of contiguous user IDs between two user namespaces. The fields are interpreted as follows: (1) The start of the range of user IDs in the user namespace of the process pid. (2) The start of the range of user IDs to which the user IDs specified by (1) are mapped. (3) The length of the range that is mapped between the two user namespaces.

>**Name**
>
> unshare - run program with some namespaces unshared from parent
>
>**Synopsis** 
>
>unshare [options] [program [arguments]]
>
>**Description**
>
> Unshares the indicated namespaces from the parent process and then executes the specified program. If program is not given, then ``${SHELL}'' is run (default: /bin/sh).  

We will now start our container environment with the `unshare` tool by unsharing/creating a new user namespace and mapping uid=1000 (external) to uid=0 (internal). Notice that all namespace descriptors are the same, except for the unshared user namespace. Furthermore, the uid_map indicates that uid=0 is mapped to uid=1000 on the root environment for a range of 1.
```
$ unshare --map-root-user --user
# id
uid=0(root) gid=0(root) groups=0(root) nogroups

# ls -la /proc/self/ns
total 0
dr-x--x--x 2 root root 0 Mar 13 13:51 .
dr-xr-xr-x 9 root root 0 Mar 13 13:51 ..
lrwxrwxrwx 1 root root 0 Mar 13 13:51 cgroup -> cgroup:[4026531835]
...
lrwxrwxrwx 1 root root 0 Mar 13 13:51 user -> user:[4026532135]
...

# cat /proc/self/uid_map
         0       1000          1

# echo $$
11222
```
Do not exit the container shell and identify its pid (in our example pid=11222).

>Terminology: v1 operated on **threads** (`tasks` file, per-controller). v2 mostly manages **processes**: adding a pid to a cgroup moves *all* of its threads at once, and the list of member processes is read from `cgroup.procs`.

We shall now create a named cgroup in the **unified** v2 tree to demonstrate how groups of processes can be controlled. The "freezer" is no longer a separate controller with its own mount — freezing is a **core** v2 feature available in *every* cgroup via the `cgroup.freeze` file.
Please start the following in an additional shell as real root user.
```
# id
uid=0(root) gid=0(root) groups=0(root)

# ls /sys/fs/cgroup/
cgroup.controllers      cgroup.threads            io.pressure
cgroup.events           cgroup.type               io.stat
cgroup.freeze           cpu.pressure              io.weight
cgroup.max.depth        cpu.stat                  memory.pressure
cgroup.max.descendants  cpuset.cpus.effective     memory.stat
cgroup.procs            cpuset.mems.effective     memory.zswap.current
cgroup.stat             init.scope                system.slice
cgroup.subtree_control  io.cost.model             user.slice
...
```
One single directory — no per-controller mounts. The root shows the controllers the kernel knows (`cat /sys/fs/cgroup/cgroup.controllers`: `cpuset cpu io memory hugetlb pids rdma misc`), plus the generic files and systemd's top-level slices (`user.slice`, `system.slice`, `init.scope`).

Now create a cgrpup directory (a cgroup) named "test" and move your container's pid into it. The generic file you write a pid into is `cgroup.procs`:
```
# cd /sys/fs/cgroup/
# mkdir test; cd test

# ls
cgroup.controllers      cgroup.procs           cpu.uclamp.max       memory.low
cgroup.events           cgroup.stat            cpu.uclamp.min       memory.max
cgroup.freeze           cgroup.subtree_control io.max               memory.min
cgroup.kill             cgroup.threads         io.stat              memory.peak
cgroup.max.depth        cgroup.type            io.weight            memory.pressure
cgroup.max.descendants  cpuset.cpus            memory.current       memory.zswap.max
cgroup.memory.events    cpu.idle               memory.events        pids.current
cgroup.memory.reclaim   cpu.max                memory.events.local  pids.events
cgroup.memory.zswap...  cpu.pressure           memory.high          pids.max
...
# echo 11222 > cgroup.procs
```
Notice that even without enabling any controller, the leaf cgroup already shows v2's *core* files plus the resource files of controllers that have no "root-only" restriction.

In your container, now check `/proc/self/cgroup`. Notice that your process environment has been moved to the cgroup `/test` in the single `0::` hierarchy:
```
# cat /proc/self/cgroup
0::/test
```
Let's go back to the root shell and freeze the `/test` cgroup. Instead of v1's `freezer.state` with the words `FROZEN`/`THAWED`, v2 uses a simple boolean:
```
# echo 1 > cgroup.freeze
```
Your container shell is now not responsive. The process (group) has been frozen. You can unfreeze/thaw the process again as follows:
```
# echo 0 > cgroup.freeze
```
Notice that the tty buffered all keys which were pressed and with the process digesting stdin again, all input is unleashed.

There is one elegant detail worth watching, which shows how much cleaner v2 is: while the cgroup is frozen, inspect the *event* files (they are pollable, so tools like systemd can be notified instead of polling):
```
# cat cgroup.events
populated 1
frozen 1
```

Clean up by moving the shell back to its systemd slice (or just exit it) and removing the cgroup. A cgroup can only be removed once it has no member processes (`populated 0`):
```
# exit                      # leave the container shell (in its terminal)
# rmdir /sys/fs/cgroup/test
```

>Where is the freezer in real containers? Docker, containerd, Kubernetes and systemd all drive exactly this file: `docker pause` → `echo 1 > cgroup.freeze` on the container's cgroup, `docker unpause` → `echo 0`. Everything else in this course is the same principle — containers are just cgroups + namespaces wrapped in an API.
