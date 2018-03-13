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
# TYPE_SPEED=20

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN}➜ ${CYAN}# "
TYPE_SPEED=10

# hide the evidence
clear

pe "ls -la /proc/self/ns"
pe "cat /proc/self/cgroup"
pe "cgcreate -g cpu,memory,blkio,devices,pids,freezer:/sandbox"
pe "cgget -r cpu.shares /sandbox"
pe "cgset -r cpu.shares=5 /sandbox"
pe "cgexec -g cpu,memory,blkio,devices,pids,freezer:/sandbox unshare --mount --ipc --pid --fork chroot container"
