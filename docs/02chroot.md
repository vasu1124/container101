# 02 Play with chroot

From Wikipedia:
The chroot system call was introduced during development of Version 7 Unix in 1979, in order to test its installation and build system.

For a chrooted program to successfully start, the chroot directory must be populated with a minimum set of these files.

This can make chroot difficult to use as a general sandboxing mechanism.

>**Name**
>
>  chroot - run command or interactive shell with special root directory
>
> **Synopsis**
>
>  chroot [OPTION] NEWROOT [COMMAND [ARG]...]
>
>**Description**
>
> Run COMMAND with root directory set to NEWROOT.

### Exercise

Let's create a fresh container directory and fill it with some binaries (e.g. typical shell tools) and in the end call chroot on it:
```
mkdir -p container/bin
cd container
cp /bin/bash ./bin
```
That is not enough, because `bash` depends on some libraries which also need to be copied into our container directory since we need to be fully self sufficient. You can inspect the binary with `ldd` (read the manpage, `objdump`is a safer option):
```
ldd /bin/bash
	linux-vdso.so.1 =>  (0x00007fff57bc6000)
	libtinfo.so.5 => /lib/x86_64-linux-gnu/libtinfo.so.5 (0x00007f210544f000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f210524b000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f2104e81000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f2105678000)
```
`ldd` lists all the required libs and where to find them. The `linux-vdso.so.1` is a "vDSO" (virtual dynamic shared object), that is a small shared library that the kernel automatically maps into the address space of all user-space applications. So we can skip that library. Some lines point directly to the library used, others have a `=>` followed by an absolute path to the library; the hex number is the address where the library will be loaded.

More convinient is the `lddtree` tool, which also inspects recursive dependancies of libraries and prints a flat list:
```
lddtree -l /bin/bash
  /bin/bash
  /lib64/ld-linux-x86-64.so.2
  /lib/x86_64-linux-gnu/libtinfo.so.5
  /lib/x86_64-linux-gnu/libdl.so.2
  /lib/x86_64-linux-gnu/libc.so.6
```

The helper script `copywithlib.sh` helps to copy a binary with all dependancies from the root environment into a folder:
```
copywithlib.sh /bin/bash .
'/bin/bash' -> './bin/bash'
'/lib64/ld-linux-x86-64.so.2' -> './lib64/ld-linux-x86-64.so.2'
'/lib/x86_64-linux-gnu/libtinfo.so.5' -> './lib/x86_64-linux-gnu/libtinfo.so.5'
'/lib/x86_64-linux-gnu/libdl.so.2' -> './lib/x86_64-linux-gnu/libdl.so.2'
'/lib/x86_64-linux-gnu/libc.so.6' -> './lib/x86_64-linux-gnu/libc.so.6'
```

Let us copy a couple of nice to have binaries:
```
copywithlib.sh /bin/ls
copywithlib.sh /bin/mkdir
copywithlib.sh /bin/ps
copywithlib.sh /bin/mount
copywithlib.sh /bin/cat
copywithlib.sh /bin/pwd
copywithlib.sh /bin/hostname
copywithlib.sh /usr/bin/stress
```

Now we are set, the container folder contains a small container-environment with a couple of binaries and their libraries. Switch into the container folder with `chroot` and look around:
```
chroot .

bash-4.3# pwd
/

bash-4.3# ls -la
total 24
drwxr-xr-x 6 0 0 4096 Mar 13 11:41 .
drwxr-xr-x 6 0 0 4096 Mar 13 11:41 ..
drwxr-xr-x 2 0 0 4096 Mar 13 11:41 bin
drwxr-xr-x 3 0 0 4096 Mar 13 11:40 lib
drwxr-xr-x 2 0 0 4096 Mar 13 11:40 lib64
drwxr-xr-x 3 0 0 4096 Mar 13 11:41 usr

bash-4.3# ps
Error, do this: mount -t proc proc /proc

bash-4.3# mkdir /proc
bash-4.3# mount -t proc proc /proc

bash-4.3# ps -efa
UID        PID  PPID  C STIME TTY          TIME CMD
0            1     0  0 03:34 ?        00:00:35 /sbin/init
0            2     0  0 03:34 ?        00:00:00 [kthreadd]
...
1000      9351  8327  0 11:04 ?        00:00:08 htop
0         9356     2  0 11:04 ?        00:00:00 [kworker/u4:2]
0        10863  3786  0 12:01 ?        00:00:00 /bin/bash -i
0        10870 10863  0 12:02 ?        00:00:00 ps -efa

bash-4.3# echo $$
10863

bash-4.3# exit
exit
```

`chroot` only "mapped" your container filesystem to the root level "/". All other namespaces were not mapped. Therefore, once you mounted `/proc`, the `ps` tools was able to look into all running processes. Furthermore, our container was not isolated at all, changes in the container were reflected in the inherited root environment and have to be cleaned:
```
# mount | grep "/proc"
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
proc on /home/vagrant/container/proc type proc (rw,relatime)
# umount /home/vagrant/container/proc
```

### Busybox
If you are now gathering a list of all your favorite utilities and want to build upon our container v1.0 example above, you should have a look at [busybox](https://www.busybox.net) (later we shall also visit [Alpine Linux](https://alpinelinux.org/)).

BusyBox is a multipurpose single executable, optimized in size, that combines many common Unix utilities:
```
apt-get install busybox-static

mkdir -p busybox/bin
cd busybox
cp /bin/busybox bin/

./bin/busybox
BusyBox v1.27.2 (Ubuntu 1:1.27.2-2ubuntu3.2) multi-call binary.
BusyBox is copyrighted by many authors between 1998-2015.
Licensed under GPLv2. See source distribution for detailed
copyright notices.

Usage: busybox [function [arguments]...]
   or: busybox --list[-full]
   or: busybox --install [-s] [DIR]
   or: function [arguments]...

	BusyBox is a multi-call binary that combines many common Unix
	utilities into a single executable.  The shell in this build
	is configured to run built-in utilities without $PATH search.
	You don't need to install a link to busybox for each utility.
	To run external program, use full path (/sbin/ip instead of ip).

Currently defined functions:
	[, [[, acpid, add-shell, addgroup, adduser, adjtimex, arch, arp, arping, ash, awk, base64, basename, beep,
...
	who, whoami, whois, xargs, xxd, xz, xzcat, yes, zcat, zcip
```

With BusyBox you can prime your container quikly with allmost 400 tools:
```
./bin/busybox --install ./bin/
chroot . /bin/sh

# inside the chroot environment
mkdir /proc
mount -t proc proc /proc
top
```

### Next ...
In the next sections we will learn how to utilize proper namespace virtualization/isolation and cgroups.
