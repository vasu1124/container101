# 08 · Tuning of Permissions & Security

> **Goal**: Understand the capability model and how Docker exposes it; run a container with capabilities *added* or *removed*.

There are many Linux security facilities (capabilities, SELinux, AppArmor, seccomp, ...). Containers, being process primitives, are subject to them. Before we look at syscall filtering (chapter 09), let's start with capabilities.

---

## What is a capability?

For permission checks, traditional Unix distinguishes two categories of processes:

- **Privileged processes** — effective UID = 0 (superuser/root). Bypass almost all kernel permission checks.
- **Unprivileged processes** — effective UID != 0. Subject to full kernel checking via credentials.

Rather than "root does everything", the kernel splits root privileges into about 40 fine-grained **capabilities** (e.g. `CAP_CHOWN`, `CAP_NET_RAW`, `CAP_SYS_ADMIN`). Each process carries three sets:

| Set | Purpose |
|-----|---------|
| Permitted | capabilities the process is allowed to use |
| Effective | capabilities currently active |
| Inheritable | capabilities kept across `execve()` |

The Docker runtime starts containers with a small default set — most of the powerful ones are already dropped.

---

## Exercise — capabilities in a container

Docker has direct support for adding (`--cap-add`) or dropping (`--cap-drop`) capabilities. By default, Docker uses a **whitelist** — it gives the container only the most commonly-needed capabilities ([the default list](https://github.com/moby/moby/blob/master/oci/defaults.go#L14-L30) contains ~14 of ~40).

### Hostname — allowed only if we add SYS_ADMIN

With default capabilities, a container can read its own hostname but cannot change it:

```bash
docker run --rm alpine:latest /bin/sh -c '
hostname
hostname inacontainer
'
6bba1c8e3d70
hostname: sethostname: Operation not permitted
```

Add the capability:

```bash
docker run --rm --cap-add SYS_ADMIN alpine:latest /bin/sh -c '
hostname inacontainer
hostname
'
inacontainer
```

And verify the host was not affected:

```bash
hostname           # on the host
container101
```

### What capabilities does a container have by default?

Ask `capsh` (from package `libcap`):

```bash
docker run --rm alpine:latest /bin/sh -c '
apk add -q libcap
capsh --print
'
Current: cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap=ep
Bounding set =cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap
...
uid=0(root) euid=0(root)
gid=0(root)
```

That's the runtime default — `cap_sys_admin` and `cap_net_raw` are both there. Let's try to take `cap_net_raw` away.

### Dropping NET_RAW

One tricky thing first: on modern kernels, `ping` can fall back to **ICMP datagram sockets** via `net.ipv4.ping_group_range`, so it may still succeed even with no `cap_net_raw`. A cleaner raw-socket demo is **traceroute**, which truly needs raw IP access:

```bash
docker run --rm alpine:latest /bin/sh -c 'traceroute -n -m2 -w1 8.8.8.8'
traceroute to 8.8.8.8 (8.8.8.8), 2 hops max, 46 byte packets
 1  172.17.0.1  0.003 ms  0.001 ms  0.001 ms
```

Now drop the capability:

```bash
docker run --rm --cap-drop NET_RAW alpine:latest /bin/sh -c 'traceroute -n -m2 -w1 8.8.8.8'
traceroute: socket(AF_INET,3,1): Operation not permitted
```

The kernel refused the raw socket. That's the security boundary in action: the container's root user still cannot do what the capability was asked for.

---

## What this means

- Containers are **secure by default** because they run with a very small set of capabilities.
- However, **root inside a container is *not* the same as root on the host**. Mount points, kernel modules, and network are typically already out of reach.
- Use `--cap-add` sparingly (SYS_ADMIN is a particularly broad one).
- Use `--cap-drop ALL` for the most locked-down containers, and only add back what you need.

---

## Next →

In [chapter 09](09syscalls.md) we dive into **system calls** — the lowest level of the user/kernel interface — and see how to filter them per-container.

[Back to top](../README.md)
