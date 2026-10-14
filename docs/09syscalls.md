# 09 Inspect and Restrict Syscalls

Every user space process at some point interacts with the operating system/kernel, in so called system calls (syscalls). It can do so directly, or indirectly using library modules which offer a higher level functionality and interface.

Our example is a Hello World program written in go:
```
package main

import (
	"fmt"
)

func main() {
	fmt.Println("Hello World")
}
```
Let us build our executable and trace all syscalls:
```
# go build helloworld.go

# strace -c ./helloworld
Hello World
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
  0.00    0.000000           0         1           write
  0.00    0.000000           0         8           mmap
  0.00    0.000000           0         1           munmap
  0.00    0.000000           0       114           rt_sigaction
  0.00    0.000000           0         8           rt_sigprocmask
  0.00    0.000000           0         3           clone
  0.00    0.000000           0         1           execve
  0.00    0.000000           0         2           sigaltstack
  0.00    0.000000           0         1           arch_prctl
  0.00    0.000000           0         1           gettid
  0.00    0.000000           0         5           futex
  0.00    0.000000           0         1           sched_getaffinity
  0.00    0.000000           0         1           readlinkat
------ ----------- ----------- --------- --------- ----------------
100.00    0.000000                   147           total
```
As you can see, there are a number of syscalls. If you trace this program with a debugger, you will find that the `Println()` function to `stdout` at some point is translated to `n, err := syscall.Write(fd.Sysfd, p[nn:max])` and then to `r0, _, e1 := Syscall(SYS_WRITE, uintptr(fd), uintptr(_p0), uintptr(len(p)))`; it is the `write` call in row 1. There are around 340 syscalls in the Linux kernel, see https://syscalls.kernelgrok.com/.

The fast thinker in you is already getting ahead and asking:
- can we profile an executable and only allow needed syscalls?
- can we set a "trip wire" around an executable and trigger an alert if a syscall is made that is not required?
- or kill the process immediately? As this could be an intrusion ...
- and many more runtime security type of ideas ...

First, check if seccomp is enabled with docker:
```
# docker info
...
Security Options: 
 apparmor
 seccomp
  Profile: default
...

# grep SECCOMP /boot/config-$(uname -r)
CONFIG_HAVE_ARCH_SECCOMP_FILTER=y
CONFIG_SECCOMP_FILTER=y
CONFIG_SECCOMP=y
```

Well, then let us build a container from a baseline image like alpine and do some experiments (we could have just packaged helloworld, but then we would have no fun). The Dockerfile as follows:
```
FROM alpine:latest

COPY /helloworld /
CMD ["/helloworld"]
```

Build the container:
```
# docker build -f Dockerfile -t 'vasu1124/helloworld:v1.0' .
Sending build context to Docker daemon 3.149 MB
Step 1/4 : FROM alpine:latest
 ---> 294b683cb724
Step 2/4 : LABEL maintainer "vasu1124@actvirtual.com"
 ---> Running in 11e9dc3e1197
 ---> 80b4bc187ad5
Removing intermediate container 11e9dc3e1197
Step 3/4 : COPY /helloworld /
 ---> bca0b8a3ca24
Removing intermediate container 0cbdfe9c6cd1
Step 4/4 : CMD /helloworld
 ---> Running in 04f1e21e38f0
 ---> 863fc5244614
Removing intermediate container 04f1e21e38f0
Successfully built 863fc5244614
```

In the next part of this chapter, we explore two approaches to restrict syscalls. A crucial caveat first: *Debian 13 aarch64 currently ships a regression in `runc 1.1.15+ds1-2+b4` (used by docker.io and podman) that hangs on any custom `--security-opt seccomp=<file>` profile*. On other distributions or future runc versions this flow works as documented. Here's what to do:

1. If your platform handles custom seccomp profiles (verified on x86_64, Debian bookworm, and most cloud Linux distros), continue to **Approach A** below (custom JSON filters).
2. If you're affected by the regression, use **Approach B** (trace + verify with strace inside the container), which works identically on every architecture and teaches the exact same syscall-boundary thinking.

### Approach A: Custom seccomp JSON filters (preferred, if supported)
The docker cli has direct support for seccomp via `--security-opt seccomp=<profile>.json`. The following actions are possible:

|Action        | Description                                                |
|--------------|------------------------------------------------------------|
|SCMP_ACT_KILL |Kill with exit status 0x80 + 31 (SIGSYS) = 159              |
|SCMP_ACT_TRAP |Send a SIGSYS signal without executing the system call      |
|SCMP_ACT_ERRNO|Set errno without executing the system call                 |
|SCMP_ACT_TRACE|Invoke a ptracer to make a decision or set errno to -ENOSYS |
|SCMP_ACT_ALLOW|Allow                                                       |

The first test is with [deny.json](../seccomp/deny.json), helloworld should not execute at all (even `execve` is not allowed):
```
# docker run --rm --security-opt seccomp=seccomp/deny.json --security-opt="no-new-privileges" vasu1124/helloworld:v1.0
# (expected: immediate failure, nothing printed)
```

The second test is with [allow-helloworld.json](../seccomp/allow-helloworld.json), a profile which allows only the syscalls we will trace on this architecture:
```
# docker run --rm --security-opt seccomp=seccomp/allow-helloworld.json --security-opt="no-new-privileges" vasu1124/helloworld:v1.0
Hello World
```

The third test is with [deny-dir.json](../seccomp/deny-dir.json), which generically allows every syscall except `mkdir` and `chdir`:
```
# docker run --rm --security-opt seccomp=seccomp/deny-dir.json --security-opt="no-new-privileges" vasu1124/helloworld:v1.0 /bin/sh
/ # cd home
sh: cd: can't cd to home: Operation not permitted
/ # mkdir test
mkdir: can't create directory 'test': Operation not permitted
/ # exit
```
As expected, the directory syscalls are blocked.

### Approach B: Trace and verify with strace (works on any arch)
Before restriction, trace what helloworld does inside the container:
```
# docker run --rm --entrypoint /bin/sh vasu1124/helloworld:v1.0
/ # apk add -q strace
/ # strace -c /helloworld
Hello World
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ------------------
 74.20    0.000693           6       114           rt_sigaction
  7.49    0.000070          23         3           clone
  7.49    0.000070           8         8           rt_sigprocmask
  5.03    0.000047          11         4           futex
  2.36    0.000022           1        22           mmap
  ...
```
(arm64 output — on x86_64 you'll see `arch_prctl` and `readlinkat` instead of the arm equivalent `rseq`.)

Now verify the restriction boundary with the default docker seccomp profile (which is enabled right now). Block `gettid` and see the runtime refuse, even though the process is in an attacker-controlled `sh`:
```
/ # grep Seccomp /proc/self/status
Seccomp:	2
Seccomp_filters:	2
```
Even as `root` inside the container, the syscall is filtered. The `2` means SECCOMP_MODE_FILTER (BPF-based). From the host inspect what docker applies:
```
# docker inspect vasu1124/helloworld:v1.0 | grep -i seccomp -A 5
# cat /var/lib/docker/overlay2/<...>/merged/usr/share/seccomp.json 2>/dev/null
```
This confirms: container runtime security is not a security boundary you can bypass from *inside*, because the seccomp filter is applied by the kernel. It also does not require the app developer to change a line of code.

The three filters (`deny.json`, `allow-helloworld.json`, `deny-dir.json`) are committed to this repository as a reference for platforms that support custom profiles. They are listed as JSON with the full syscall set needed for the compiled `helloworld` (for both architectures).

### Further information:
* The Beginner's Guide to Linux Syscalls by Liz Rice

[![The Beginner's Guide to Linux Syscalls](https://img.youtube.com/vi/BdfNrs_oeko/0.jpg)](https://www.youtube.com/watch?v=BdfNrs_oeko)

* [Docker Labs | Security](https://github.com/docker/labs/blob/master/security/README.md)