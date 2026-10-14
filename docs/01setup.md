# 01 Setup

Have [vagrant](https://www.vagrantup.com) configured in your environment. `git clone` this project into your workspace and start a vagrant box (Vagrantfile provided in the repo) with
`vagrant up` and enter the virtual machine with `vagrant ssh`. Beware of and adjust for corporate proxies, which hinder remote downloads.

The provided Vagrantfile targets a Debian 13 (trixie) ARM64 box (Apple Silicon / UTM / VirtualBox) and automatically provisions the tools used in this tutorial via cloud-init: `docker.io`, `pv`, `htop`, `stress`, `golang-go`, `pax-utils`, `busybox-static`, `strace`, `rsync`, and `make`. Check your VM with `vagrant ssh`, and verify tools are installed.

### If you already have a Linux system

You can also install the required tools manually (here an example with `apt-get` for Debian/Ubuntu):

```
sudo apt-get update
sudo apt-get install -y docker.io
sudo apt-get install -y pv
sudo apt-get install -y htop
sudo apt-get install -y stress
sudo apt-get install -y pax-utils
sudo apt-get install -y sysdig
sudo apt-get install -y cgroup-tools
sudo apt-get install -y golang-go
```

Note: the orginal excercise was with the `rkt`. That package is no longer maintained and is not available in current Debian/Ubuntu. We now use `systemd-nspawn` instead.

Unless otherwise noted, all examples/exercises are executed with `root` privileges (in the vagrant box, prefix commands with `sudo` as needed).
