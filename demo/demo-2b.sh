#!/usr/bin/env bash

########################
# include the magic
########################
. /vagrant/demo/demo-magic.sh


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
rmdir /sys/fs/cgroup/freezer/test
clear

pe "ls -la /sys/fs/cgroup"
pe "cd /sys/fs/cgroup/freezer"
pe "ls -la"
pe "mkdir test"
pe "cd test"
pe "ls -la"
pe "cat tasks"
cmd
pe "cat tasks"
pe "echo FROZEN >freezer.state"
pe "echo THAWED >freezer.state"
wait
