# Container 101


If you ever had to deal with repairing or modifying an installed Linux system (reset root password, resizing/checking partitions or file systems), you should be familiar with the concept of booting a live cd image and `chroot`-ing to the installed system.

As more features around cgroups & namespaces where [introduced](https://www.youtube.com/watch?v=YsYzMPptB-k) to Linux, I just experimented with these new features via [LXC](https://linuxcontainers.org/) only for special purposes, while still relying on virtual machines for my daily work. The google project [LMCTFY](https://www.linuxplumbersconf.org/2013/ocw//system/presentations/1239/original/lmctfy%20(1).pdf) was a first wakeup call for me to pay closer [attention](https://www.youtube.com/watch?v=doUktZIcXF0). I was reminded again of a [course in Plan 9](http://www.vorlesungen.uni-osnabrueck.de/informatik/Plan9/), where many of the concepts had been imho already introduced:

>Design Principles derived from [Plan 9 from Bell Labs](https://en.wikipedia.org/wiki/Plan_9_from_Bell_Labs):
>
>The foundations of the system are built on two ideas: a per-process name space and a simple message-oriented file system protocol.
>— Pike et al.
> * Processes each have their own isolated view of the namespace (cf. [Linux mount, pid, net, ..., cgroups](https://en.wikipedia.org/wiki/Linux_namespaces)).
> * Processes can offer their services to other processes by providing virtual files that appear in the other processes' namespace, across the boundary of a single computer.
> * Processes can collect the files from different directory trees in a single union directory (cf. [Docker AUFS, device mapper, lvm, brtfs/zfs](https://docs.docker.com/storage/storagedriver/select-storage-driver/)).
> * ... combination of many other innovations (cf. Linux special filesystems like /proc or /sys, everything unicode).

I put together the following introduction to containers with the goal to jump start a newcomer into this subject with some very easy to understand exercises. And I have inserted links to many superb experts & bloggers and original documentation, so you can dive deeper into further material.

## Exercises

### [01 Setup](docs/01setup.md)

### [02 Play with chroot](docs/02chroot.md)

### [03 Play with cgroups & namespaces](docs/03cgroups.md)

### [04 Play with cgroups & namespaces (Part 2)](docs/04cgroups.md)

### [05 Let's create a Docker image and run it](docs/05docker.md)

### [06 Swarm Intelligence with Docker Registry](docs/06registry.md)

### [07 What about rkt?](docs/07rocket.md)

### [08 Tuning of Permissions & Security](docs/08security.md)

### [09 Inspect and Restrict Syscalls](docs/09syscalls.md)

## Further Reading
- [A Brief History of Containers: From the 1970s Till Now](https://blog.aquasec.com/a-brief-history-of-containers-from-1970s-chroot-to-docker-2016). And if you are interested in real containers, [the history of containers](https://mccontainers.com/blog/the-history-of-containers/) has some good material 
- [A Practical Introduction to Container Terminology](https://developers.redhat.com/blog/2018/02/22/container-terminology-practical-introduction/) by Scott McCarty
- [Docker Labs](https://github.com/docker/labs/blob/master/README.md) (docker specific)
- [The Missing Introduction To Containerization](https://medium.com/devopslinks/the-missing-introduction-to-containerization-de1fbb73efc5) by Aymen El Amri, a very nice in-depth article on the history with examples.