# 01 Setup
Have [vagrant](https://www.vagrantup.com) configured in your environment. `git clone` this project into your workspace and start a vagrant box (Vagrantfile provided in the repo) with 
`vagrant up` and enter the virtual machine with `vagrant ssh`. Beware of and adjust for corporate proxies, which hinder remote downloads.

Or if you have an ubuntu system at hand, you can also install the required tools manually:
```
apt-get update
apt-get install -y docker.io
apt-get install -y pv
apt-get install -y htop
apt-get install -y stress
apt-get install -y pax-utils
apt-get install -y sysdig
apt-get install -y cgroup-tools
wget https://dl.google.com/go/go1.10.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.10.linux-amd64.tar.gz
echo 'export PATH=${PATH}:/usr/local/go/bin' >>/etc/profile
gpg --update-trustd
gpg --recv-key 18AD5014C99EF7E3BA5F6CE950BDD3E0FC8A365E
wget https://github.com/rkt/rkt/releases/download/v1.29.0/rkt_1.29.0-1_amd64.deb
wget https://github.com/rkt/rkt/releases/download/v1.29.0/rkt_1.29.0-1_amd64.deb.asc
gpg --verify rkt_1.29.0-1_amd64.deb.asc
dpkg -i rkt_1.29.0-1_amd64.deb
```

Unless otherwise noted, all examples/excercises are executed with `root`-privileges.
