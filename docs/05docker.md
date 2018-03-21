# 05 Let's create a Docker image and run it

>**Name**
>
>docker - Docker image and container command line interface
>
>**Synopsis**
>
>docker [OPTIONS] COMMAND [ARG...]
>
>**Description**
>
>is a client for interacting with the daemon (see dockerd(8)) through the CLI.
>
>The Docker CLI has over 30 commands. The commands are listed below and each has its own man page which explain usage and arguments.

### Exercise

First, we import the container environment into the docker image system. We identify our image with a label `1.0`, as `container:1.0`
```
# cd container; tar -c . | docker import - container:1.0
sha256:b4197ce506759484e02653134666fd2c747d9fe83dacff9916627acc83265ba2

# docker images
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
container             1.0                 b4197ce50675        4 seconds ago       7.97 MB
```

With the docker image, we can now utilize docker to setup namespaces & cgroups (and networks and volumes) and run your container. Notice, how a number of dependencies automatically have been taken care of for you, e.g. the virtual file systems `/proc`, `/sys` & `/dev` have been already provided in your mount namespace, a random hostname has been configured (and if we had the `ip` tool, you would find a namespaced network), even the folder  `/etc` has been provisioned with useable/correct information. And you find that docker automatically sets cgroup boundaries: 
```
# docker run -it container:1.0 /bin/bash
bash-4.3# hostname
e8c4dbbede0c

bash-4.3# ls -la
total 28
drwxr-xr-x  14 0 0 4096 Mar 14 22:00 .
drwxr-xr-x  14 0 0 4096 Mar 14 22:00 ..
-rwxr-xr-x   1 0 0    0 Mar 14 22:00 .dockerenv
drwxr-xr-x   2 0 0 4096 Mar 13 11:41 bin
drwxr-xr-x   5 0 0  360 Mar 14 22:00 dev
drwxr-xr-x   2 0 0 4096 Mar 14 22:00 etc
drwxr-xr-x   3 0 0 4096 Mar 13 11:40 lib
drwxr-xr-x   2 0 0 4096 Mar 13 11:40 lib64
dr-xr-xr-x 136 0 0    0 Mar 14 22:00 proc
dr-xr-xr-x  13 0 0    0 Mar 12 15:01 sys
drwxr-xr-x   3 0 0 4096 Mar 13 11:41 usr

bash-4.3# ps -efa
UID        PID  PPID  C STIME TTY          TIME CMD
0            1     0  0 22:00 ?        00:00:00 /bin/bash
0            6     1  0 22:00 ?        00:00:00 ps -efa

bash-4.3# mount
none on / type aufs (rw,relatime,si=59999008a60a5cf5,dio,dirperm1)
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
tmpfs on /dev type tmpfs (rw,nosuid,mode=755)
...
tmpfs on /sys/firmware type tmpfs (ro,relatime)

bash-4.3# ls -la /etc
total 20
drwxr-xr-x  2 0 0 4096 Mar 14 22:00 .
drwxr-xr-x 14 0 0 4096 Mar 14 22:00 ..
-rw-r--r--  1 0 0   13 Mar 14 22:00 hostname
-rw-r--r--  1 0 0  174 Mar 14 22:00 hosts
lrwxrwxrwx  1 0 0   12 Mar 14 22:00 mtab -> /proc/mounts
-rw-r--r--  1 0 0  191 Mar 14 22:00 resolv.conf

bash-4.3# cat >I-was-here
covfefe
<ctrl-d>

bash-4.3# cat /proc/self/cgroup
11:blkio:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d
10:memory:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d
9:perf_event:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d
8:freezer:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d
7:hugetlb:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d
6:pids:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d
5:net_cls,net_prio:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d
4:cpu,cpuacct:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d
3:cpuset:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d
2:devices:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d
1:name=systemd:/docker/300a44334bca84724e1a549c0942ee76549f258258b468d896532fefb042592d

bash-4.3# exit
exit
```
The various competing ways of bootstrapping the container process is today standardized under the [Open Container Initiative (OCI)](https://www.opencontainers.org/), and Docker has donated its container format and runtime implementation [runC]( https://github.com/opencontainers/runc) to the OCI.

In order to find out, if your code is running inside a docker environment, you can [check](https://github.com/minio/minio/pull/1330) for `/.dockerenv`:
```
if ! [ -f /.dockerenv ] ; then
  echo "Not running inside docker, exiting to avoid data damage." >&2
  exit 1
fi
```

Docker has its own `ps` facility. It can not only list running docker container, but also containers which were run in the past. Furthermore, the last state (write layer) of a container is retained and can be inspected:
```
# docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS               NAMES
e8c4dbbede0c        container:1.0       "/bin/bash"         45 seconds ago      Exited (0) 5 seconds ago                       vibrant_chandrasekhar
```
Unless you name a runtime instance, docker will auto-generate a [human readable name](https://github.com/moby/moby/blob/master/pkg/namesgenerator/names-generator.go) (which can be hilarious if the workload coincidentally correlates).

### immutability
The image we built and ran is [*immutable*](https://en.wikipedia.org/wiki/Immutable_object). It is a core principle which [Docker introduced](https://www.youtube.com/watch?v=_DOXBVrlW78) to containers and now also a fundament for cloud native architecture. If we wanted to include some changes and had rebuilt the image, it finally would get a new hash identifier (`sha256:b4197ce50...`) which you can re-tag - hopefully you will remember to increment the version number -  as `container:1.1`.

How do you live this immutability in practice? If you run the command `docker run -it container:1.0 /bin/bash` again, you will find that all changes you had made in the last run are lost, the container has been initialized with a fresh startup environment (cf. [copy-on-write and layers](https://docs.docker.com/storage/storagedriver/)). In fact, to emphasize this ephemeral (or transient) behavior, you can't even rely on a static hostname. This principle forces you to store configuration & state outside your runtime/container (and forgo of binding configuration to a hostname, ip or MAC address; this poses quite some challenges for traditional/static licensing models). So when a container crashes or stops, you must re-establish your "last-known-good" on a fresh baseline.

The docker system does retain the state of all *runs* (cf. `ps` facility) and you can re-start & attach into a previously started container (identified by it human readable name) with:
```
# docker start -ai vibrant_chandrasekhar
bash-4.3# ls -la I*
-rw-r--r-- 1 0 0 5 Mar 17 08:05 I-was-here
bash-4.3# cat I-was-here
covfefe
 
```

### cleanup
Hav a look at the docker system facility to keep the docker runtime in check:
```
# docker system df
TYPE                TOTAL               ACTIVE              SIZE                RECLAIMABLE
Images              5                   2                   216.4 MB            208.5 MB (96%)
Containers          5                   0                   110 B               110 B (100%)
Local Volumes       0                   0                   0 B                 0 B

# docker system prune
WARNING! This will remove:
	- all stopped containers
	- all volumes not used by at least one container
	- all networks not used by at least one container
	- all dangling images
Are you sure you want to continue? [y/N] y
Deleted Containers:
fcb44efc01002d1b20a1f218affbeb19399e43fd4eb79e7550bb5526f9892922
...

```

If you haven't googled it by now, visit https://docs.docker.com/ for further documentation on docker.

### Next ...

In the next section we will share our container with the world. But more astonishing, we shall consume containers created by the world/community with shocking ease.