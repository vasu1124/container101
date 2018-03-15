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

cd $dir/..

pe "docker build -f Dockerfile -t 'vasu1124/helloworld:v1.0' ."
pe "docker run --rm vasu1124/helloworld:v1.0"
pe "docker run --rm --security-opt seccomp=seccomp/deny.json vasu1124/helloworld:v1.0"
