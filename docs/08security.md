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

So for example, if you are in a container with your own uts namespace, why would an application level process want to change the hostname? With default capabilities, it cannot:
```
# docker run -it alpine:latest /bin/sh
/ # hostname
4a2d48b21058
/ # hostname inacontainer
hostname: sethostname: Operation not permitted
/ # exit
```
But if you do need to do so, you can add a powerful capability (but beware of side effects, where else could this power be misused?):
```
# docker run -it --cap-add SYS_ADMIN alpine:latest /bin/sh
/ # hostname
870343e22fa2
/ # hostname inacontainer
/ # hostname
inacontainer
/ # exit
exit
# hostname
container101
```

On many Linux distributions you'll find ping configured with cap_net_raw (which allows ping to create raw sockets), on some ping is still configured to runs as root via setuid bit (set user ID upon execution).

On our host, we will inspect ping's configuration. Alpine's `ping` is a symlink to the privileged `busybox` binary and busybox binary commands are either setuid or figure out permissions at runtime.
```
# ls -la /bin/ping
lrwxrwxrwx    1 root     root            12 Sep 17 17:32 /bin/ping -> /bin/busybox
```

BusyBox's own capabilities on Alpine:
```
# docker run -it alpine:latest /bin/sh
/ # apk add -q libcap
/ # capsh --print
Current: cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap=ep
Bounding set =cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap
...
uid=0(root) euid=0(root)
gid=0(root)
...
```

Now that we are familiar with this facility, we will start a container with dropped capability NET_RAW. On modern kernels, `ping` can fall back to ICMP datagram sockets (via net.ipv4.ping_group_range) and might still work. A clearer raw-socket demo is `traceroute`, which requires raw IP access:
```
# docker run -it alpine:latest /bin/sh
/ # traceroute 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 46 byte packets
 1  172.17.0.1 (172.17.0.1)  0.003 ms  0.009 ms  0.002 ms
/ # exit

# docker run -it --cap-drop NET_RAW alpine:latest /bin/sh
/ # traceroute 8.8.8.8
traceroute: socket(AF_INET,3,1): Operation not permitted
/ # exit
exit
```

The statements "secure by default" or "software is safer in containers" relates to the adjusted process environments.

From a security perspective, containers offer the option to reduce attack surfaces and isolate applications to include only the required components, interfaces, libraries and network connections. But the developer or user has to make a well informed effort, security is not a free option.