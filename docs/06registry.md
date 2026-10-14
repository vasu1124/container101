# 06 · Container Registries

> **Goal**: Push your image to a public registry. Pull someone else's. Understand how a global container ecosystem actually works.

Obtain a free account at your favorite hosted Container Registry; the most common ones are [Docker Hub](https://hub.docker.com/), [Quay](https://quay.io/), or a private [GitHub Container Registry](https://ghcr.io). In this tutorial we use Docker Hub because it's the default registry for the Docker CLI.

---

## Exercise — push your image to Docker Hub

Before pushing, we need two things: authentication, and a **tag** that tells Hub under which repository name to store the image.

```bash
cd /home/vagrant/container101/container

# 1. Tag with your Docker ID (mine is vasu1124)
docker tag container:1.0 vasu1124/container:1.0

# 2. Log in (one time only, credentials are cached in ~/.docker/config.json)
docker login
Login with your Docker ID to push and pull images from Docker Hub. 
Username: vasu1124
Password: <password>
Login Succeeded

# 3. Push
docker push vasu1124/container:1.0
The push refers to repository [docker.io/vasu1124/container]
5b73e1d6f17e: Pushed
1.0: digest: sha256:c668d2784a267f29ee6c397537c48454c3dba829da2f513b37a5fafd16975fac size: 527
```

If you now browse to `https://hub.docker.com/r/vasu1124/container/tags/`, you will see your image publicly accessible.

![repo](container.png)

Now try it in reverse — from a *fresh* machine with Docker installed:

```bash
docker run -it vasu1124/container:1.0 /bin/bash
```

If that works, you've just experienced the whole value proposition: **standardized packaging + standardized distribution**. No more "works on my machine".

---

## Understanding what just happened

- The registry stores **layers** identified by sha256. When you push, it uploads the diff between local and remote.
- The **tag** (`vasu1124/container:1.0`) is just a human label pointing at a digest.
- Anyone can pull it — but each puller gets the same bits, no rebuild required.

Container registries are a core piece of the container ecosystem; they are also mostly free up to a limit. Useful registries:

- **Docker Hub** (default) — largest public registry
- **Quay.io** — operated by Red Hat
- **GitHub Container Registry (ghcr.io)** — free for public repos
- **AWS ECR / Google GCR / Azure ACR** — cloud-native, integrated with IAM
- **Harbor / Artifactory** — self-hosted

---

## Pull a popular community image

Let's search for a small, well-maintained base image. **`Alpine`** is today's choice for minimal containers (only 5 MB!):

```bash
docker search --no-trunc alpine
NAME                DESCRIPTION                                                                                         STARS     OFFICIAL
alpine              A minimal Docker image based on Alpine Linux with a complete package index and only 5 MB in size!   11563     [OK]
alpine/git          A  simple git container running in alpine linux, especially for tiny linux distro.                  252
alpine/socat        Run socat command in alpine container                                                               120
alpine/curl                                                                                                             14
```

The `alpine` line has 11.5k stars and is an **official** Docker image. That means it's maintained and reviewed.

> Docker Hub shows a couple of KPIs: stars (popularity), official-image flag, automated-build flag.

---

## Pull and inspect Alpine

```bash
docker run -it alpine:latest /bin/sh

Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
a9986cd6f37d: Pull complete
Digest: sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6
Status: Downloaded newer image for alpine:latest

/ # cat /etc/os-release
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.24.2
PRETTY_NAME="Alpine Linux v3.24"
...

/ # ls /bin | wc -l
82

/ # du -sh /
8.9M    /

/ # uname -a
Linux 9977cc543267 6.12.107+deb13-arm64 #1 SMP Debian 6.12.107-1 (2026-08-29) aarch64 Linux

/ # exit
```

**Wait.** `uname -a` inside the container says *Debian 6.12.107+deb13-arm64* — but the host is Debian 13. The kernel is shared — containers **do not have their own kernel**. That's the whole point of containers.

Compare with the host:

```bash
cat /etc/os-release              # on the host
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
...
```

So a musl-libc-based Alpine userland runs on top of a Debian (glibc-tuned) kernel. This is normal in container-land — containers package *userspace*, not *kernel*.

---

## Export

You can also go in the reverse direction and export a container root filesystem to a tarball:

```bash
mkdir alpine-export && cd alpine-export

# (Assuming the alpine container you ran above is still alive; `docker ps -a` to find ID)
docker export <container-id> | tar xf - 
```

Your `alpine-export/` directory now contains a complete Alpine v3.24 root filesystem. If you figure out how to get a kernel and initrd to boot from (see https://github.com/linuxkit/linuxkit), this becomes the installer for an operating system.

---

## Curated images from Docker

For production use, prefer verified images:

- https://hub.docker.com/explore/ — community picks
- https://store.docker.com/ — verified publisher program

Many vendors publish official images (Ubuntu, Postgres, Nginx, ...). They are maintained, signed, and often scanned for known vulnerabilities.

---

## Trust

There are two CNCF projects managing cryptographic trust for images & contents:

- [The Update Framework (TUF)](https://github.com/theupdateframework/specification) — incremental, rollback-resistant updates
- [Notary](https://github.com/theupdateframework/notary) — signing and verification of software artifacts

If you want to stop using "whatever image is on Hub", TUF/Notary-based signing is the standard.

---

## Next →

In [chapter 07](07nspawn.md), we look at an alternative container runtime — one built directly on top of systemd.

[Back to top](../README.md)
