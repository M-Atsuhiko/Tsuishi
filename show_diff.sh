#! /bin/bash
#author: Atsuhiko Murakami

if ! [ -n "$1" ]
then
    echo "input filename"
    exit -1
fi

filename=$1
Dir="./former_prog/"

diff ${filename} ${Dir}${filename}
