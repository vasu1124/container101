#!/usr/bin/env bash

########################
# include the magic
########################
dir="${0%/*}"
. $dir/demo-magic.sh


########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
TYPE_SPEED=40

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN}➜ ${CYAN}# "
TYPE_SPEED=10

# hide the evidence
# cleanup a possibly previous run
if [ -d /sys/fs/cgroup/sandbox ]; then
  cat /sys/fs/cgroup/sandbox/cgroup.procs 2>/dev/null | while read -r pid; do
    echo "$pid" > /sys/fs/cgroup/cgroup.procs 2>/dev/null
  done
  rmdir /sys/fs/cgroup/sandbox 2>/dev/null
fi
clear

# NOTE: run as ROOT from the folder containing your `container` image.

pe "cat /proc/self/cgroup"
pe "stat -fc %T /sys/fs/cgroup"
pe "cd /sys/fs/cgroup"

# 1) delegate the controllers down the root of the unified tree
pe 'echo "+cpu +memory +io +pids" > cgroup.subtree_control'

# 2) create the sandbox cgroup and apply limits
pe "mkdir sandbox"
pe "cat sandbox/cgroup.controllers"
pe "echo 10000 > sandbox/cpu.max"        # v2: quota/period -> 10000/100000 = ~10% of one CPU
pe "cat sandbox/cpu.max"

# 3) move this shell into the cgroup...
pe 'echo $$ > /sys/fs/cgroup/sandbox/cgroup.procs'

# 4) ... and start the namespaced container (use the rootfs built in 02)
pe "cd /home/vagrant/container101/container"
pe "unshare --mount --uts --ipc --pid --fork chroot . /bin/bash"

# everything below happens inside (pe resumes when you exit)
p "bash-5.2# mkdir -p /proc; mount -t proc proc /proc"
p "bash-5.2# cat /proc/self/cgroup     # 0::/sandbox"
p "bash-5.2# hostname hugabuga"
p "bash-5.2# stress -c 2      # from outside: watch sandbox/cpu.stat nr_throttled"
p "bash-5.2# exit"
p "# cleanup: rmdir /sys/fs/cgroup/sandbox"

wait
