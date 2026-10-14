# 05 · Create a Docker image and run it

> **Goal**: Package your chapter-02 rootfs as a Docker image, store it under Docker's management, and let Docker set up namespaces/cgroups/network for you.

Docker's CLI (~30 sub-commands) is a client for the `dockerd` daemon (see `dockerd(8)`). This chapter uses it for *image* creation and *runtime* control.

---

## Exercise — import a custom rootfs

We have the chroot from chapter 02 sitting in a directory. Let's turn it into a Docker image named `container:1.0`:

```bash
cd /home/vagrant/container101/container
tar -c . | docker import - container:1.0
sha256:b4197ce506759484e02653134666fd2c747d9fe83dacff9916627acc83265ba2

docker images
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
container             1.0                 b4197ce50675        4 seconds ago       7.97 MB
```

(The image ID is a sha256. The size matches our rootfs ≈8 MB.)

## Run it

```bash
docker run -it container:1.0 /bin/bash

bash-5.2# hostname
e8c4dbbede0c        # <- random hostname

bash-5.2# ls -la
total 24
-rwxr-xr-x   1 0 0    0 Oct 14 16:50 .dockerenv
drwxrwxr-x   2 1000 1000 4096 Oct 14 16:50 bin
drwxr-xr-x   5 0 0  340 Oct 14 16:50 dev
drwxr-xr-x   2 0 0 4096 Oct 14 16:50 etc
drwxrwxr-x   3 1000 1000 4096 Oct 14 16:50 lib
dr-xr-xr-x 114 0 0    0 Oct 14 16:50 proc
dr-xr-xr-x  13 0 0    0 Oct 14 16:50 sys
drwxrwxr-x   3 1000 1000 4096 Oct 14 16:50 usr
```

Docker has automatically:

- set up `/proc`, `/sys`, `/dev` — the virtual filesystems,
- created `/etc/hostname`, `/etc/hosts`, `/etc/resolv.conf`,
- created the marker file `/.dockerenv` (see below),
- configured a cgroup namespace (see `/proc/self/cgroup`),
- set the hostname,
- configured a network (with a private IP — you would see via `ip`).

And `/proc/self/cgroup` shows a single v2 line:

```bash
bash-5.2# cat /proc/self/cgroup
0::/
```

Docker runs the container in a dedicated cgroup and hides the path — from *inside* you see `/`. (In chapter 03 you set `0::/sandbox` manually; this is the same pattern.)

---

## How do I know I'm inside Docker?

Test for the marker file:

```bash
if ! [ -f /.dockerenv ]; then
  echo "Not running inside Docker" >&2
  exit 1
fi
```

`.dockerenv` is the canonical Docker indicator. (See [minio#1330](https://github.com/minio/minio/pull/1330) for an alternative `cgroup`-based method if you don't want the file dependency.)

---

## Docker's `ps`

```bash
docker ps -a
CONTAINER ID   IMAGE         COMMAND       CREATED          STATUS                     PORTS     NAMES
634877128d15   container:1.0 "/bin/bash"    45 seconds ago   Exited (0) 5 seconds ago             vibrant_chandrasekhar
```

(Unless you name a container, Docker generates a random one — often funny. See `namesgenerator` in the moby source.)

---

## Immutability

The image is *immutable*. Re-running the container gives you a fresh copy. This is a core property.

```bash
docker run -it container:1.0 /bin/bash        # fresh every time
```

If you need to change the image, **rebuild it** and re-tag to `1.1`. (Each rebuild creates a new sha256 ID.)

### Old state isn't lost — just ramified

If you started, modified, then exited a container, you can restart it without rebuilding:

```bash
docker start -ai vibrant_chandrasekhar

bash-5.2# ls -la I-was-here
-rw-r--r-- 1 0 0 5 Oct 14 16:50 I-was-here
bash-5.2# cat I-was-here
covfefe
```

Notice we did *not* re-import the rootfs — the container's write layer is preserved.

---

## Cleanup

Docker's internal metadata about images and containers accumulates. Two tools:

```bash
docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          1         1         8.555MB   0B (0%)
Containers      4         0         0B        0B
...

docker system prune
WARNING! This will remove:
        - all stopped containers
        - all volumes not used by at least one container
        - all networks not used by at least one container
        - all dangling images
Are you sure you want to continue? [y/N] y
```

Use `prune` (or targeted `docker image rm` / `docker container rm`) to keep the system tidy.

---

## Documentation

Official Docker docs: https://docs.docker.com/. The various runtime bootstrap implementations are today standardized under the [Open Container Initiative (OCI)](https://www.opencontainers.org/) — Docker has donated its container format and runtime (runC) to OCI.

---

## Next →

In [chapter 06](06registry.md), we publish our image to a public registry — and consume images built by others.

[Back to top](../README.md)
