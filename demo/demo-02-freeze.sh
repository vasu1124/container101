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

# hide the evidence
# cleanup a possibly previous run: move processes out & remove the cgroup
if [ -d /sys/fs/cgroup/test ]; then
  cat /sys/fs/cgroup/test/cgroup.procs 2>/dev/null | while read -r pid; do
    echo "$pid" > /sys/fs/cgroup/cgroup.procs 2>/dev/null
  done
  rmdir /sys/fs/cgroup/test 2>/dev/null
fi
clear

# NOTE: run this demo as ROOT (sudo ./demo-02-freeze.sh).
# In parallel, have an `unshare --map-root-user --user` shell running
# and note its PID (see demo-02-unshare.sh); you will be asked for it.

pe "stat -fc %T /sys/fs/cgroup        # cgroup2fs => we are on v2"
pe "ls /sys/fs/cgroup"
pe "cat /sys/fs/cgroup/cgroup.controllers"
pe "mkdir /sys/fs/cgroup/test"
pe "cd /sys/fs/cgroup/test"
pe "ls"
# prepare: ask for the unshare-shell pid and move it into the cgroup
p "echo <pid-of-your-unshared-shell> > cgroup.procs"
clear
cmd
pe "cat cgroup.procs"
pe "cat cgroup.events"
# freeze
pe "echo 1 > cgroup.freeze"
pe "cat cgroup.events"
p "# go type in your frozen shell... it is unresponsive"
wait
# thaw
pe "echo 0 > cgroup.freeze"
p "# the shell digests everything you typed"
wait

# cleanup
pe "cat cgroup.procs"
p "# exit the contained shell before removing the cgroup"
pe "cd /sys/fs/cgroup"
pe "rmdir test"
wait
