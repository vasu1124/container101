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
p "copying\n ... /bin/ls\n ... /bin/mkdir\n ... /bin/ps\n ... /bin/mount\n ... /bin/cat\n ... /bin/pwd\n ... /bin/hostname\n ... /usr/bin/stress"
$dir/copywithlib.sh /bin/ls
$dir/copywithlib.sh /bin/mkdir
$dir/copywithlib.sh /bin/ps
$dir/copywithlib.sh /bin/mount
$dir/copywithlib.sh /bin/cat
$dir/copywithlib.sh /bin/pwd
$dir/copywithlib.sh /bin/hostname
$dir/copywithlib.sh /usr/bin/stress

pe "ls -laR"
pe "chroot ."

pe "pwd"
pe "ls"
pe "mount"
pe "umount proc"
wait
