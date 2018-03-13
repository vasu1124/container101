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
rm -rf container
clear

pe "mkdir container"
pe "cd container"
pe "mkdir bin"
pe "cp /bin/bash ./bin"
pe "ldd /bin/bash"
pe "mkdir lib lib64"
pe "$dir/copywithlib.sh /bin/bash"
pe "$dir/copywithlib.sh /bin/ls"
pe "$dir/copywithlib.sh /bin/mkdir"
pe "$dir/copywithlib.sh /bin/ps"
pe "$dir/copywithlib.sh /bin/mount"
pe "$dir/copywithlib.sh /bin/cat"
pe "$dir/copywithlib.sh /bin/pwd"
pe "$dir/copywithlib.sh /bin/hostname"
pe "ls -laR"
pe "chroot ."

pe "pwd"
pe "ls"
pe "mount"
pe "umount proc"
wait
