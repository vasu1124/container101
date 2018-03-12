# container 101
Play with container

## Setup
Have vagrant configured in your environment. Start your vagrant box with 
`vagrant up` and enter the virtual machine with `vagrant ssh`. Beware of and adjust for corporate proxies, which hinder remote downloads.

Or if you have an ubuntu system at hand, you can also install manually:
```
apt-get update
apt-get install -y docker.io
apt-get install pv
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

## Play with chroot
todo: copy from slides
## Play with namespaces & cgroups
todo: copy from slides
## Play with namespaces & cgroups 2
todo: copy from slides
## Let's create a Docker image and run it
todo: copy from slides
## Swarm Intelligence with Docker Registry
todo: copy from slides
## What about Rocket?
todo: copy from slides
## Fine Tuning of Permissions
todo: copy from slides


