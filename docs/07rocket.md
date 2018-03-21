# 07 What about rkt?

A quick look into the other open source container runtime from CoreOS: [rkt](https://coreos.com/rkt/).

(I have not looked at [railcar](https://github.com/oracle/railcar) or other options yet).

The rkt cli includes many similar option as docker. In fact, there is a newer option to directly download images from Docker Hub and run them, which we are going to use. The process model from rkt and docker substantially [differ](https://coreos.com/rkt/docs/latest/rkt-vs-other-projects.html#rkt-vs-docker):
![process model](https://coreos.com/rkt/docs/latest/rkt-vs-docker-process-model.png)

The docker cli commands are effectively executed by a daemon process, which deviates from best practices for Unix process and privilege separation. As an answer, Docker has added a number of [security](https://docs.docker.com/engine/security/security/) measures. 

When rkt was announced it caused a lot of [stir](https://news.ycombinator.com/item?id=8682525),today Kubernetes with its [CRI](http://blog.kubernetes.io/2016/12/container-runtime-interface-cri-in-kubernetes.html) can effectively mask the details of the underlying container engine. Beware that some features, e.g. re-adjusting cgroup resource constraints of an already running container (`docker update ...`), are not supported via Kubernetes. 

### Exercise

Let us run our `container:1.0` image and inspect the filesystem:
```
# rkt run --interactive --insecure-options=image docker://vasu1124/container:1.0 -- /bin/bash
Downloading sha256:6089112fedd [=============================] 3.72 MB / 3.72 MB

bash-4.3# ls -la
total 40
drwxr-xr-x   1 0 0 4096 Mar 17 20:57 .
drwxr-xr-x   1 0 0 4096 Mar 17 20:57 ..
drwxr-xr-x   2 0 0 4096 Mar 13 11:41 bin
drwxr-xr-x   1 0 0 4096 Mar 17 20:57 dev
drwxr-xr-x   2 0 0 4096 Mar 17 20:57 etc
drwxr-xr-x   3 0 0 4096 Mar 13 11:40 lib
drwxr-xr-x   2 0 0 4096 Mar 13 11:40 lib64
dr-xr-xr-x 132 0 0    0 Mar 17 20:57 proc
drwxr-xr-x   3 0 0 4096 Mar 17 20:57 run
dr-xr-xr-x  13 0 0    0 Mar 12 15:01 sys
drwxrwxrwt   2 0 0 4096 Mar 17 20:57 tmp
drwxr-xr-x   3 0 0 4096 Mar 13 11:41 usr
```
Looks like rkt is bootstraping the container environment a little different than docker, e.g. the folders `/run` and `/tmp`. There is (of course) no tag file `.dockerenv`.

```
bash-4.3# hostname
rkt-e870efe8-ca56-40b2-9755-a0d00b553ca7
```
Ok, the hostname is also auto-generated and has a rkt prefix.

```
bash-4.3# ps -efa
UID        PID  PPID  C STIME TTY          TIME CMD
0            1     0  0 20:57 ?        00:00:00 /usr/lib/systemd/systemd --default-standard-output=tty --log-target=null --s
0            2     1  0 20:57 ?        00:00:00 /usr/lib/systemd/systemd-journald
0            7     1  0 20:57 console  00:00:00 /bin/bash
0           14     7  0 21:00 console  00:00:00 ps -efa

bash-4.3# ls -la run
total 12
drwxr-xr-x 3 0 0 4096 Mar 17 20:57 .
drwxr-xr-x 1 0 0 4096 Mar 17 20:57 ..
drwxr-xr-x 3 0 0 4096 Mar 17 20:57 systemd
```
Observe that a proper systemd and journald facility has been [started](https://coreos.com/rkt/docs/latest/devel/architecture.html) in the container. In fact, the initial environment resembles a minimal systemd system without any applications installed, except for the systemd-journald service. On host systems running systemd, rkt will attempt to integrate with journald on the host where the container logs can be accessed directly via journalctl.

What is intransparent though, is that the path to `/usr/lib/systemd` is not mapped and you have to bring your own journalctl in your image. rkt starts & supplies process 1 & 2 with external means. Anyhow, the logging facility is under [discussion](https://github.com/rkt/rkt/issues/2990)

Some more subtle differences:
```
bash-4.3# mount
overlay on / type overlay (rw,relatime, ...)
...
tmpfs on /sys/power type tmpfs (ro,nosuid,nodev,mode=755)

bash-4.3# ls -la /etc
total 12
drwxr-xr-x 2 0 0 4096 Mar 17 20:57 .
drwxr-xr-x 1 0 0 4096 Mar 17 20:57 ..
-rw-r--r-- 1 0 0    0 Mar 17 20:57 hostname
-rw-r--r-- 1 0 0  327 Mar 17 20:57 hosts
```
Looks like there is no compatible `resolv.conf` supplied. That is because rkt requires you to make a conscious decision if you want to map the host dns (or any other) configuration with `--dns host` into the container 

### Further information
You can now explore the option to build your own OCI compliant container runtime. Here are some pointers to get you started with 'containers from scratch': 
* [Build Your Own Container Using Less than 100 Lines of Go](https://www.infoq.com/articles/build-a-container-golang) by Julz Friedman

* DockerCon 2017 Talk by Liz Rice 

[![What Have Namespaces Done for You Lately?](https://img.youtube.com/vi/MHv6cWjvQjM/0.jpg)](https://www.youtube.com/watch?v=MHv6cWjvQjM) 

* Safari Course Video [Building Containers from Scratch with Go](https://www.safaribooksonline.com/library/view/building-containers-from/9781491988404/) by Liz Rice
