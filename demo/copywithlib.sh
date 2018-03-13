#!/bin/bash
# Author : vasu1124
# License : MIT

function useage()
{
    cat << EOFmark
Useage: $0 <binary> [destination]
copies all dependant libraries, preserving library paths into destination folder
default destination is .
library paths in destination are created dynamincally.
EOFmark
exit 1
}

#Validate the inputs
[[ $# < 1 ]] && useage
dest=$2
[[ $# < 2 ]] && dest=.

#Check if the paths are vaild
[[ ! -e $1 ]] && echo "Not a vaild input $1" && exit 1 
[[ -d $dest ]] || echo "No such directory $dest ..." 

lddtree -l $1 | while read lib
do
  dir="${lib%/*}"
  mkdir -p ${dest}${dir}
  cp -vf $lib ${dest}${lib}
done
