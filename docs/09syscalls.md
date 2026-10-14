# 09 · Inspect and Restrict Syscalls

> **Goal**: See every syscall a binary makes, then write a seccomp filter to allow only those. This is the deepest level of container "security" — it's closer to your program than capabilities or namespaces.

Every user-space process eventually asks the kernel for something — a file, a socket, a memory page. That's a **syscall**. Library calls like `printf()` compile to syscalls; syscalls are the boundary between your program and the kernel.

---

## Hello World — the syscall view

A Go Hello-World looks like one line of source:

```go
package main

import "fmt"

func main() {
    fmt.Println("Hello World")
}
```

When strace'd, it's ~170 syscalls:

```bash
cd /home/vagrant/container101
make                # builds ./helloworld

strace -c ./helloworld
Hello World
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ------------------
  0.00    0.000000           0         6           fcntl
  0.00    0.000000           0         1           openat
  0.00    0.000000           0         1           close
  0.00    0.000000           0         1           read
  0.00    0.000000           0         1           write
  0.00    0.000000           0         4           futex
  0.00    0.000000           0         1           sched_getaffinity
  0.00    0.000000           0         2           sigaltstack
  0.00    0.000000           0       114           rt_sigaction
  0.00    0.000000           0         8           rt_sigprocmask
  0.00    0.000000           0         1           rt_sigreturn
  0.00    0.000000           0         1           gettid
  0.00    0.000000           0         3           clone
  0.00    0.000000           0         1           execve
  0.00    0.000000           0        22           mmap
  0.00    0.000000           0         2           madvise
  0.00    0.000000           0         2           prlimit64
------ ----------- ----------- --------- --------- ------------------
100.00    0.000000           0       171           total
```

(The exact numbers differ per architecture and Go version — on x86-64 you'd see `arch_prctl`, `readlinkat`, `rseq`, ... The list above is from a static ARM64 build. The point: it's about 20 distinct syscall **types**; `rt_sigaction` is called 114 times.)

The `Println()` translates through the Go runtime to roughly `syscall.Write(...)`, which is the single `write` row in the count above. Around 340 distinct syscalls exist in Linux 6.x; see https://syscalls.kernelgrok.com/.

---

## The idea — could we *restrict* the syscall list?

Fast thought "what if": what if the kernel refused to run any syscall *not* in this table? An attacker's reverse shell would be dead in the water — any non-listed syscall would fail.

That feature exists; it's called **seccomp** (secure computing **mode**).

Check if our toolchain and kernel support it:

```bash
docker info
...
Security Options: 
 apparmor
 seccomp
  Profile: default
...

grep SECCOMP /boot/config-$(uname -r)
CONFIG_HAVE_ARCH_SECCOMP_FILTER=y
CONFIG_SECCOMP_FILTER=y
CONFIG_SECCOMP=y
```

---

## Exercise — build the container

The Dockerfile (alpine base):

```dockerfile
FROM alpine:latest

COPY /helloworld /
CMD ["/helloworld"]
```

Build:

```bash
cd /home/vagrant/container101
make                       # builds ./helloworld
docker build -f Dockerfile -t 'vasu1124/helloworld:v1.0' .
```

---

## Two approaches

Docker supports custom seccomp profiles via `--security-opt seccomp=<file>.json`. The container runtime (runc) reads the JSON, translates to BPF, and loads it into the kernel.

However:

> **⚠ Regression on Debian 13 aarch64**: runc 1.1.15 (shipped with Debian 13) hangs when applying any custom seccomp profile on ARM64. This is a known runc+libseccomp interaction. Two clean paths below:

1. **Track A**: you have a working Docker+runc (most x86 distros, WSL2, EC2, GCE, Docker Desktop) → run the full JSON example.
2. **Track B**: affected host (e.g. Debian 13 aarch64) → verify the same boundary from inside with `strace` + default profile.

---

### Track A: Custom seccomp profiles (most distros)

Docker's seccomp actions:

| Action | Effect |
|--------|--------|
| `SCMP_ACT_KILL` | SIGSYS, process killed |
| `SCMP_ACT_TRAP` | SIGSYS, seccomp user-space trap handler invoked |
| `SCMP_ACT_ERRNO` | syscall returns an `errno` (e.g. `EPERM`) |
| `SCMP_ACT_TRACE` | invoke a ptracer, can allow or deny |
| `SCMP_ACT_ALLOW` | allow the syscall |

The seccomp profiles for helloworld (matching both aarch64 and x86_64 architectures):

- [deny.json](../seccomp/deny.json) — deny everything — nothing runs.

```bash
docker run --rm \
  --security-opt seccomp=seccomp/deny.json \
  --security-opt="no-new-privileges" \
  vasu1124/helloworld:v1.0
# → silent failure, nothing printed
```

- [allow-helloworld.json](../seccomp/allow-helloworld.json) — allow only the listed syscalls — binary works fine.

```bash
docker run --rm \
  --security-opt seccomp=seccomp/allow-helloworld.json \
  --security-opt="no-new-privileges" \
  vasu1124/helloworld:v1.0
Hello World
```

- [deny-dir.json](../seccomp/deny-dir.json) — allow everything **except** `mkdir` and `chdir` — attacker can't navigate or create directories.

```bash
docker run --rm \
  --security-opt seccomp=seccomp/deny-dir.json \
  --security-opt="no-new-privileges" \
  vasu1124/helloworld:v1.0 /bin/sh
/ # cd home
sh: cd: can't cd to home: Operation not permitted
/ # mkdir test
mkdir: can't create directory 'test': Operation not permitted
```

---

### Track B: In-container verification (platform-independent)

Every Docker container is already under a seccomp filter. Inspect it from inside:

```bash
docker run --rm --entrypoint sh vasu1124/helloworld:v1.0 -c '
grep Seccomp /proc/self/status
'
```

```
Seccomp:        2
Seccomp_filters:        4
```

- `Seccomp: 2` means `SECCOMP_MODE_FILTER` is active.
- `Seccomp_filters` shows the number of prctl-loaded BPF filter programs.

This is running **no matter what you run** — Docker ships ~60 allowed syscalls in its default profile and blocks the rest.

Now trace the binary's syscalls from inside the container:

```bash
docker run --rm --entrypoint sh vasu1124/helloworld:v1.0 -c '
apk add -q strace
strace -c /helloworld
'
Hello World
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ------------------
 74.20    0.000693           6       114           rt_sigaction
 ...
```

The same list as on the host, now under Docker's default filter. Every syscall above is in the allowlist — this is the practical, everyday seccomp layer you already use.

You can even inspect **from the host** what the filter allows:

```bash
docker inspect vasu1124/helloworld:v1.0 | grep -i seccomp -A 5
```

---

## Why seccomp is special

- **No userland involved** — the kernel decides, so userspace tricks can't bypass it.
- **Toolchain-agnostic** — works for Go, C, shell, python — anything that makes syscalls.
- **No root required** — combined with namespaces (chapter 03), an attacker who breaks through the app *still* can't get the host to do privileged work.

That's why Docker, containerd, Kubernetes, and every modern runtime use it by default.

---

## Further reading

- Video [The Beginner's Guide to Linux Syscalls](https://www.youtube.com/watch?v=BdfNrs_oeko) — Liz Rice
- Hands-on [Docker Labs | Security](https://github.com/docker/labs/blob/master/security/README.md)

---

**Back to top** → [../README.md](../README.md)
