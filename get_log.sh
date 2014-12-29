#! /bin/bash
#author: Atsuhiko Murakami

if [ -n "$1" ]
then
    SERVERs=$1
else
    SERVERs=(hal1 hal2 hal3 hal4)
fi

LOG_DIR="/home/murakami/"
LOG_NAME="nohup.out"
FINISH_FILE="end_nohup.out"

LS="ls"
ECHO="echo"

date

for server in ${SERVERs[@]}
do
    LS_Command="ssh ${server} ${LS} ${LOG_DIR}${LOG_NAME}"
    eval ${LS_Command}
    ECHO_RESULT="ssh ${server} ${ECHO} $?"
    result=`eval ${ECHO_RESULT}`
    if [ ${result} -eq 0 ]
    then
	SCP_Command="scp ${server}:${LOG_DIR}${LOG_NAME} ./${server}.out"
    else
	SCP_Command="scp ${server}:${LOG_DIR}${FINISH_FILE} ./${server}.out"
    fi
    eval ${SCP_Command}
done






