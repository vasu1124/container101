# 07 What about rkt? → systemd-nspawn (updated)

>Historical note: this chapter originally covered CoreOS **rkt** — an alternative OCI-compatible container runtime that pioneered a systemd-native process model, upstream-Docker image support, and hard security defaults. **rkt was archived in February 2020** (CNCF [announcement](https://www.cncf.io/blog/2020/02/24/cncf-archives-the-rkt-project/)) and is no longer installable. The idea it championed — *containers started and supervised like system services* — did not die with it; it **won**. Today it exists as:
>1. **CGroups/namespace delegation** — the "process model" rkt introduced is now the de-facto standard: runc-mediated containers from Docker/containerd run directly under a systemd-owned cgroup, just like rkt did.
>2. **systemd-nspawn** — the shipping, maintained spiritual successor, native to all systemd distros (no extra daemon, no special image format, and can run a raw rootfs like the one you built in 02).

We update the exercise to **systemd-nspawn** — same lesson, current tool.

### Process model: Docker (daemon) vs nspawn (direct)
The docker cli sends commands to a long-running root daemon (`dockerd`), which then asks containerd/runc to set up namespaces & cgroups. This extra supervisor layer deviates from classic Unix process separation, and is why Docker later added process-signaling hardening and rootless mode.
![process model](https://coreos.com/rkt/docs/latest/rkt-vs-docker-process-model.png)

`systemd-nspawn`, in contrast, is just a normal parent process of your container PID 1 — closer to `chroot` with namespaces + cgroups bolted on. No daemon, no sidecar.

### Exercise

Use the rootfs you created in 02 (`~/container101/container`). nspawn can run any directory that looks like an OS tree — i.e. `bin/` + `lib/` + `usr/` are enough.

See how nspawn boots a *full* systemd init (PID 1) by default:
```
# cd /home/vagrant/container101/container
# systemd-nspawn -D . 
Spawning container container on /home/vagrant/container101/container.
container login: 
```
Simply hit Enter, but we're not going to log in yet — abort with `Ctrl`+`]` three times, or drop the default `--boot` and run a single command as PID 2 instead:
```
# systemd-nspawn -D . --as-pid2 /bin/bash
Spawning container container on /home/vagrant/container101/container.

bash-5.2# ps -efa
UID        PID  PPID  C STIME TTY          TIME CMD
0            1     0  0 19:03 ?        00:00:00 (sd-stubinit)
0            2     1  0 19:03 pts/0    00:00:00 /bin/bash
0           14     2  0 19:03 pts/0    00:00:00 ps -efa
```
`(sd-stubinit)` is a tiny PID-1 stub that just handles zombie-reaping and signals; your image doesn't need to contain `systemd`, and you don't get a daemon in the container either — the middle ground between rkt's full-init and Docker's fork.exec.

Notice what's in and out of the container view:
```
bash-5.2# ls -la
total 24
drwxrwxr-x 2 1000 1000 4096 Oct 14 16:50 bin
drwxr-xr-x 5 0    0     340 Oct 14 16:50 dev
drwxr-xr-x 2 0    0    4096 Oct 14 16:50 etc
drwxr-xr-x 3 1000 1000 4096 Oct 14 16:50 lib
dr-xr-xr-x 114 0    0       0 Oct 14 16:50 proc
dr-xr-xr-x 13 0    0       0 Oct 14 16:50 sys
drwxrwxr-x 3 1000 1000 4096 Oct 14 16:50 usr

bash-5.2# hostname
container

bash-5.2# cat /proc/self/cgroup
0::/
```
The hostname is the directory name, not random — and the cgroup namespace is masked as `0::/`, exactly as Docker does today.

But just like rkt, nspawn makes you *decide* about host data: by default it *does* map the host's `/etc/resolv.conf` in read-only (compare with rkt that required `--dns host`), and it doesn't create a Docker-style `.dockerenv` marker.

### Where this is used in 2025
- `systemd-nspawn` is the "no-frills" runner shipped with systemd; good for quick chroot-like isolation with namespaces.
- Its successor for "real" service-style containers is today mostly `systemd` *itself* via transient scopes (see `systemd-run` in chapter 04), Docker/containerd (cgroup v2 native), and Kubernetes.
- The "image is just a directory / OCI concept is portable" lesson from rkt is now also normalized in the OCI image-spec and the OCI runtime-spec.

### Further information
Explore building your own OCI compliant container runtime with 'containers from scratch':
* [Build Your Own Container Using Less than 100 Lines of Go](https://www.infoq.com/articles/build-a-container-golang) by Julz Friedman

* DockerCon 2017 Talk by Liz Rice

[![What Have Namespaces Done for You Lately?](https://img.youtube.com/vi/MHv6cWjvQjM/0.jpg)](https://www.youtube.com/watch?v=MHv6cWjvQjM) 

* Safari Course Video [Building Containers from Scratch with Go](https://www.safaribooksonline.com/library/view/building-containers-from/9781491988404/) by Liz Rice
