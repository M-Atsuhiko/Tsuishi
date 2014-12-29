#! /bin/bash
#author: Atsuhiko Murakami

if [ -z $1 ]
then
    echo "input sent file"
    exit 2
fi

SERVERs=(hal1 hal2 hal3 hal4)

DIR="/home/murakami/workspace/"

for server in ${SERVERs[@]}
do
    SCP_Command="scp $1 ${server}:${DIR}"
    echo ${SCP_Command}

    eval ${SCP_Command}
done







