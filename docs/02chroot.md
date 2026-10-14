# 02 · Play with chroot

> **Goal**: Understand the oldest isolation primitive on Unix — `chroot` — and why it alone is *not* a container.

The [`chroot()`](https://man7.org/linux/man-pages/man2/chroot.2.html) system call was introduced in Version 7 Unix (1979) to test the OS installation. The idea: run a process that believes the root directory (`/`) is some subdirectory. Everything outside that directory is invisible to the process.

It sounds like a container. It isn't — but it's the *gateway*.

---

## What chroot actually needs

For a chrooted program to start, its new root must contain a minimal userland:

- The **binary** (e.g., `/bin/bash`)
- Its **shared libraries** (glibc, ld-linux)
- The **dynamic loader** itself

Let's see what we need for bash.

### Inspect the dependencies

```bash
# ldd prints the libraries a binary needs
$ ldd /bin/bash
    linux-vdso.so.1 (0x0000ffff9fbec000)
    libtinfo.so.6 => /lib/aarch64-linux-gnu/libtinfo.so.6 (0x0000ffff9f9e0000)
    libc.so.6 => /lib/aarch64-linux-gnu/libc.so.6 (0x0000ffff9f820000)
    /lib/ld-linux-aarch64.so.1 (0x0000ffff9fbb0000)
```

> **Architecture note**: This is ARM64 (`aarch64`) output. On x86-64 the paths are `/lib/x86_64-linux-gnu/...` and the loader is `/lib64/ld-linux-x86-64.so.2`. Same concept, different filenames.

`linux-vdso.so.1` is a virtual kernel mapping — no file to copy. The others must physically exist inside the chroot.

A nicer way to see the tree with recursive dependencies:

```bash
$ lddtree -l /bin/bash
/bin/bash
/lib/ld-linux-aarch64.so.1
/lib/aarch64-linux-gnu/libtinfo.so.6
/lib/aarch64-linux-gnu/libc.so.6
```

### Obtain and place the binaries

Manual copying gets tedious. The helper script `demo/copywithlib.sh` automates it:

```bash
cd /home/vagrant/container101
mkdir container && cd container

bash ../demo/copywithlib.sh /bin/bash .
# -> '/bin/bash' -> './bin/bash'
# -> '/lib/ld-linux-aarch64.so.1' -> './lib/ld-linux-aarch64.so.1'
# -> '/lib/aarch64-linux-gnu/libtinfo.so.6' -> './lib/aarch64-linux-gnu/libtinfo.so.6'
# -> '/lib/aarch64-linux-gnu/libc.so.6' -> './lib/aarch64-linux-gnu/libc.so.6'
```

Grab a few more utilities (each with their deps):

```bash
for b in /bin/ls /bin/mkdir /bin/ps /bin/mount /bin/cat /bin/pwd /bin/hostname /usr/bin/stress; do
  bash ../demo/copywithlib.sh $b .
done
```

---

## Exercise 1 — Enter the chroot

```bash
$ chroot .

bash-5.2# pwd
/

bash-5.2# ls -la
total 24
drwxr-xr-x 6 0 0 4096 Nov  1 12:34 .
drwxr-xr-x 6 0 0 4096 Nov  1 12:34 ..
drwxr-xr-x 2 0 0 4096 Nov  1 12:34 bin
drwxr-xr-x 3 0 0 4096 Nov  1 12:34 lib
drwxr-xr-x 2 0 0 4096 Nov  1 12:34 lib64
drwxr-xr-x 3 0 0 4096 Nov  1 12:34 usr

bash-5.2# ps
Error, do this: mount -t proc proc /proc
```

Notice: `ps` fails immediately because there is no `/proc` inside the chroot. This is your **first lesson**: a container with an incomplete filesystem is still broken. Let's fix it:

```bash
bash-5.2# mkdir /proc
bash-5.2# mount -t proc proc /proc

bash-5.2# ps -efa
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 03:34 ?        00:00:35 /sbin/init
root         2     0  0 03:34 ?        00:00:00 [kthreadd]
...
vagrant   9351  8327  0 11:04 ?        00:00:08 htop
root      9356     2  0 11:04 ?        00:00:00 [kworker/u4:2]
root     10863  3786  0 12:01 ?        00:00:00 /bin/bash -i
root     10870 10863  0 12:02 ?        00:00:00 ps -efa

bash-5.2# echo $$
10863

bash-5.2# exit
```

You can see the **entire host's process list** — `chroot` only remapped the filesystem *view*, not the process tree or PIDs. There **was no isolation**.

### Clean up

The proc mount sticks outside the chroot. On the host:

```bash
$ mount | grep "/proc"
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
proc on /home/vagrant/container/proc type proc (rw,relatime)

$ sudo umount /home/vagrant/container/proc
```

---

## Exercise 2 — BusyBox: a complete userland in one file

Rebuilding a real Linux root filesystem by copying binaries and libraries one-by-one is painful. There's a better way: [BusyBox](https://www.busybox.net) — the Swiss-army-knife of embedded Linux. It packs ~400 Unix tools into a single statically-linked binary.

> **Goal**: create a *fully self-contained* rootfs with a single binary, then chroot into it.

```bash
cd /home/vagrant/container101
mkdir busybox && cd busybox
cp /bin/busybox bin/

./bin/busybox
# BusyBox v1.35.0 (Debian 1:1.35.0-3) multi-call binary.
# ... long usage banner ...

./bin/busybox --list | head
```

`--list` shows which programs are compiled in (e.g. `sh`, `ls`, `ps`, `top`, `mkdir`, `mount`). Let's install them as symlinks, then chroot:

```bash
./bin/busybox --install bin/
$ sudo chroot . /bin/sh

/ # mkdir /proc && mount -t proc proc /proc
/ # top
```

`top` inside the chroot shows **only host processes** — again, **no namespace isolation**. But *resource isolation* is still possible: run `stress` in a cgroup from [chapter 03](03cgroups.md).

---

## What did we learn?

| Concept | What chroot gives you | What's missing |
|--------|----------------------|----------------|
| Filesystem isolation | ✅ Yes | |
| Process isolation | ❌ No (`ps` shows all PIDs) | Namespaces |
| Resource control | ❌ No | cgroups |
| Network isolation | ❌ No | net namespace |
| User/authentication isolation | ❌ No | uid namespaces |

`chroot` is a **one-line container**, but no container at all in modern terms. Chapters 03 and 04 add the missing pieces.

---

**Next →** [03 cgroups & namespaces](03cgroups.md) — resource control via control groups
