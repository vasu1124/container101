#!/bin/bash

cp -fv $1 ./bin

ldd $1 | while read lib ignore path ignore2
do
  if [[ $lib == /lib64* ]]
  then
      cp -vf $lib ./lib64
  elif [[ $path == /* ]]
  then
    if [[ $path == /lib64* ]]
    then
      cp -vf $path ./lib64
    elif [[ $path == /lib* ]]
    then
      cp -vf $path ./lib/
    fi
  fi
done

