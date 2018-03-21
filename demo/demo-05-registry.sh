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

pe "docker login"
pe "docker tag container:1.0 vasu1124/container:1.0"
pe "docker push vasu1124/container:1.0"

pe "docker search centos"
pe "uname -a"
pe "docker run -it centos:7 /bin/bash"
