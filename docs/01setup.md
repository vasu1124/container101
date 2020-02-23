# 01 Setup
Have [vagrant](https://www.vagrantup.com) configured in your environment. `git clone` this project into your workspace and start a vagrant box (Vagrantfile provided in the repo) with 
`vagrant up` and enter the virtual machine with `vagrant ssh`. Beware of and adjust for corporate proxies, which hinder remote downloads.

Or if you have an ubuntu system at hand, you can also install the required tools manually:
```
add-apt-repository -y ppa:longsleep/golang-backports
apt-get update
apt-get install -y docker.io
apt-get install -y pv
apt-get install -y htop
apt-get install -y stress
apt-get install -y pax-utils
apt-get install -y sysdig
apt-get install -y cgroup-tools
apt-get install -y golang-go
apt-get install -y rkt
```

Unless otherwise noted, all examples/excercises are executed with `root`-privileges.
