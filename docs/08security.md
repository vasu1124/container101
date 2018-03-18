# 08 Tuning of Permissions & Security

There are a number of security facilities in Linux (capabilities, SELinux, AppArmor, seccomp, ...), and containers, since they are bound to process primitives, are of course subject to these facilities. 

>**Name**
>
>capabilities
>
>**Description**
>
>For the purpose of performing permission checks traditional UNIX implementations distinguish two categories of processes: privileged processes (whose effective user ID is 0, referred to as superuser or root), and unprivileged processes (whose effective UID is nonzero).
>
>Privileged processes bypass all kernel permission checks while unprivileged processes are subject to full permission checking based on the process's credentials (usually: effective UID, effective GID, and supplementary group list).

### Exercise

The docker cli has [direct support](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) for adding (`--cap-add`) or dropping (`--cap-drop`) capabilities. By default Docker drops all capabilities except for some [most commonly needed](https://github.com/moby/moby/blob/master/oci/defaults.go#L14-L30), a whitelist instead of a blacklist approach.

So for example, if you are in a container with your own uts namespace, why would an application level process want to change the hostname?
```
# docker run -it centos:7 /bin/bash
[root@42308ee74c3b /]# hostname
42308ee74c3b
[root@42308ee74c3b /]# hostname inacontainer
hostname: you must be root to change the host name
[root@42308ee74c3b /]# exit
```
But if you do need to do so, you can add a powerful capability (but beware of side effects, where else could this power be misused?):
```
# docker run -it --cap-add SYS_ADMIN centos:7 /bin/bash
[root@4f2d48b21058 /]# hostname
4f2d48b21058
[root@4f2d48b21058 /]# hostname inacontainer
[root@4f2d48b21058 /]# hostname
inacontainer
[root@4f2d48b21058 /]# exit
exit
# hostname
ubuntu-xenial
```

On many Linux distributions you’ll find ping configured with cap_net_raw (which allows ping to create raw sockets), on some ping is still configured to runs as root via setuid bit (set user ID upon execution).

On our Ubuntu host, we will configure ping with capabilities using `setcap cap_net_raw+ep /bin/ping` and remove the setuid bit. The “+ep” means you’re adding the capability (“-” would remove it) as Effective and Permitted.

There are 3 modes:
* e: Effective. This means the capability is “activated”.
* p: Permitted.  This means the capability can be used/is allowed.
* i: Inherited. The capability is kept by child/subprocesses upon execve() for example.
```
# ls -la /bin/ping
-rwsr-xr-x 1 root root 44168 May  7  2014 /bin/ping
# setcap cap_net_raw+ep /bin/ping
# getcap /bin/ping
/bin/ping = cap_net_raw+ep
# chmod u-s /bin/ping
# ping google.com
PING google.com (172.217.23.142) 56(84) bytes of data.
64 bytes from fra16s18-in-f14.1e100.net (172.217.23.142): icmp_seq=1 ttl=63 time=18.2 ms
^C
```

Now that we are familiar with this facility, we will start a centos container with dropped capability NET_RAW: 
```
# docker run -it --cap-drop NET_RAW centos:7 /bin/bash
[root@45b40625ae84 /]# getcap /bin/ping
/bin/ping = cap_net_admin,cap_net_raw+p
[root@45b40625ae84 /]# /bin/ping google.com
ping: socket: Operation not permitted
[root@45b40625ae84 /]# exit
exit
```

The statements "secure by default" or "software is safer in containers" relates to the adjusted process environments.
![features](https://img.scoop.it/vr-SoyYI8yKYsOf0vxriWrnTzqrqzN7Y9aBZTaXoQ8Q=)
(The table is from an excerpt of an older [Blog](https://blog.docker.com/2016/08/software-security-docker-containers/) from 2016/08)

From a security perspective, containers offer the option to reduce attack surfaces and isolate applications to include only the required components, interfaces, libraries and network connections. But the developer or user has to make a well informed effort, security is not a free option.