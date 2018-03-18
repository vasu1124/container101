# 03 Play with cgroups & namespaces

From Wikipedia: cgroups is a Linux kernel feature that limits, accounts for, and isolates the resource usage (CPU, memory, disk I/O, network, etc.) of a collection of processes.
* Engineers at Google started the work on this feature in 2006 under the name "process containers". The control groups functionality was merged into the Linux kernel mainline in kernel version 2.6.24, which was released in January 2008.

Namespaces are a feature of the Linux kernel that isolates and virtualizes system resources of a collection of processes, they are a fundamental aspect of containers on Linux.
* Linux namespaces were inspired by the more general namespace functionality used heavily throughout Plan 9 from Bell Labs.

### Exercise

Please start the following as a non-root user.
```
$ id
uid=1000(vagrant) gid=1000(vagrant) groups=1000(vagrant)
```

The Linux `/proc` system allows you to inspect namespace, cgroups and various other tables of your environment. We will now inspect a couple of pointers:
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
lrwxrwxrwx 1 root root 0 Mar 13 13:07 user -> user:[4026531837]
lrwxrwxrwx 1 root root 0 Mar 13 13:07 uts -> uts:[4026531838]
```
The listing under `/proc/self/ns/<nstype>` shows files with their respective file descriptor that can be used to identify a specific namespace. Simplified, you can think of the number as a pointer to a virtual table in the kernel.
```
$ cat /proc/self/cgroup
11:devices:/user.slice
10:memory:/user.slice
9:cpu,cpuacct:/user.slice
8:blkio:/user.slice
7:hugetlb:/
6:net_cls,net_prio:/
5:cpuset:/
4:pids:/user.slice/user-1000.slice
3:perf_event:/
2:freezer:/
1:name=systemd:/user.slice/user-1000.slice/session-3.scope
```

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
uid=0(root) gid=0(root) groups=0(root)

# ls -la /proc/self/ns
total 0
dr-x--x--x 2 root root 0 Mar 13 13:51 .
dr-xr-xr-x 9 root root 0 Mar 13 13:51 ..
lrwxrwxrwx 1 root root 0 Mar 13 13:51 cgroup -> cgroup:[4026531835]
lrwxrwxrwx 1 root root 0 Mar 13 13:51 ipc -> ipc:[4026531839]
lrwxrwxrwx 1 root root 0 Mar 13 13:51 mnt -> mnt:[4026531840]
lrwxrwxrwx 1 root root 0 Mar 13 13:51 net -> net:[4026531957]
lrwxrwxrwx 1 root root 0 Mar 13 13:51 pid -> pid:[4026531836]
lrwxrwxrwx 1 root root 0 Mar 13 13:51 user -> user:[4026532135]
lrwxrwxrwx 1 root root 0 Mar 13 13:51 uts -> uts:[4026531838]

# cat /proc/self/uid_map
         0       1000          1

# echo $$
11222
```
Do not exit the container shell and identify its pid (in our example pid=11222)

We shall now create a a named cgroup environment for the freezer subsystem to demonstrate how groups of processes can be controlled. 
Please start the following in an additional shell as real root user.
```
# id
uid=0(root) gid=0(root) groups=0(root)

# ls -la /sys/fs/cgroup/
total 0
drwxr-xr-x 13 root root 340 Mar 12 14:25 .
drwxr-xr-x 10 root root   0 Mar 12 14:57 ..
dr-xr-xr-x  6 root root   0 Mar 12 15:00 blkio
lrwxrwxrwx  1 root root  11 Mar 12 14:25 cpu -> cpu,cpuacct
dr-xr-xr-x  6 root root   0 Mar 12 15:00 cpu,cpuacct
lrwxrwxrwx  1 root root  11 Mar 12 14:25 cpuacct -> cpu,cpuacct
dr-xr-xr-x  3 root root   0 Mar 12 15:00 cpuset
dr-xr-xr-x  6 root root   0 Mar 12 15:00 devices
dr-xr-xr-x  3 root root   0 Mar 12 15:00 freezer
dr-xr-xr-x  3 root root   0 Mar 12 15:00 hugetlb
dr-xr-xr-x  6 root root   0 Mar 12 15:00 memory
lrwxrwxrwx  1 root root  16 Mar 12 14:25 net_cls -> net_cls,net_prio
dr-xr-xr-x  3 root root   0 Mar 12 15:00 net_cls,net_prio
lrwxrwxrwx  1 root root  16 Mar 12 14:25 net_prio -> net_cls,net_prio
dr-xr-xr-x  3 root root   0 Mar 12 15:00 perf_event
dr-xr-xr-x  6 root root   0 Mar 12 15:00 pids
dr-xr-xr-x  6 root root   0 Mar 12 15:00 systemd
```

Now create a subfolder or group named "test" in the freezer subsystem and associate your pid to this groups tasks:
```
# cd /sys/fs/cgroup/freezer/
# mkdir test; cd test
# echo 11222 >tasks
```

In your container, now check `/proc/self/cgroup`. Notice that your process environment has been added to the hierarchical freezer cgroup `/test`:
```
# cat /proc/self/cgroup
...
2:freezer:/test
...
```
Let's go back to the root shell and freeze the `/test`cgroup:
```
# echo "FROZEN" >freezer.state
```
Your container shell is now not responsive. The process (group) has been frozen. You can unfreeze/thaw the process again as follows:
```
# echo "THAWED" >freezer.state
```
Notice that the tty buffered all keys which were pressed and with the process digesting stdin again, all input is unleashed.
