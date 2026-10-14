# 01 · Setup

> **Goal**: Get a working Linux environment with all tools this tutorial needs.

You have two paths: the fully-managed Vagrant route (recommended) or a manual install on a recent Debian/Ubuntu.

---

## Option A — Vagrant (recommended)

This is the reference environment used to verify every chapter of this tutorial. It gives you a Debian 13 (trixie) ARM64 VM with Docker, Go, strace, and all other tools pre-installed.

```bash
git clone <this-repo>
cd container101
vagrant up
vagrant ssh
```

> **⏱ Tip**: `vagrant up` takes 3–10 minutes the first time, mostly downloading the Debian box image (≈500 MB) and provisioning packages.

The Vagrantfile uses **VirtualBox or UTM/QEMU** (Apple Silicon). If VirtualBox is not available, Vagrant automatically falls back to UTM on macOS. On Windows, VirtualBox is the default.

### Verify
```bash
vagrant ssh
sudo docker info       # should list cgroup driver, overlay storage, etc.
go version
which strace stress
```

If you see Docker and Go, you're ready for [chapter 02](02chroot.md).

---

## Option B — Manual install

If you already have a Debian/Ubuntu system (physical machine, cloud VM, WSL2):

```bash
sudo apt-get update
sudo apt-get install -y \
  docker.io \
  pv \
  htop \
  stress \
  pax-utils \
  sysdig \
  cgroup-tools \
  golang-go \
  make \
  strace
```

Then verify `docker info` and `go version` as above.

---

## Important notes

- **`sudo` everywhere**: On the VM we run everything as `root` (via `sudo`). Most namespaces/cgroups operations require root privileges.
- **Architecture matters**: Boxes are ARM64 (for Apple Silicon) or x86-64 (for Intel/AMD). The tutorial works on both — but some example output will differ. We call this out in the exercises, especially on [chapter 09](09syscalls.md).
- **No rkt**: The old rkt runtime (original chapter 07) has been archived. We use `systemd-nspawn` (bundled with systemd) instead — same idea, works everywhere systemd runs.
- **Online docs**: Image tags and versions (`debian:trixie`, `alpine:latest`) change over time. The teaching pattern matters more than the exact digest.

---

**Next →** [02 Play with chroot](02chroot.md)
