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
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

# hide the evidence
clear

pe "id"
pe "ls -la /proc/self/ns"
pe "cat /proc/self/cgroup"                 # v2: a single 0:: line (unified hierarchy)
pe "stat -fc %T /sys/fs/cgroup"            # cgroup2fs = cgroup v2
pe "cat /proc/self/uid_map"
pe "unshare --map-root-user --user"

pe "id"
pe "ls -la /proc/self/ns"
pe "cat /proc/self/cgroup"
pe "cat /proc/self/uid_map"
pe "echo $$"
p "# remember this PID - the freeze demo (demo-02-freeze.sh) will need it"
wait
