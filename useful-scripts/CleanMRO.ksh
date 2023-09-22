#!/bin/ksh

QueuesList=""
SemaphoresList=""
SharedMemList=""

ipcs -q | grep ${USER}
if [[ $? = 0 ]]
then
	QueuesList=`ipcs -q | grep ${USER} | awk '{print $2}'`
        for List1 in `echo $QueuesList`
        do
            ipcrm -q $List1
        done
fi

ipcs -s | grep ${USER}
if [[ $? = 0 ]]
then
        SemaphoresList=`ipcs -s | grep ${USER} | awk '{print $2}'`
        for List2 in `echo $SemaphoresList`
        do
            ipcrm -s $List2
        done
fi

ipcs -m | grep ${USER}
if [[ $? = 0 ]]
then
        SharedMemList=`ipcs -m | grep ${USER} | awk '{print $2}'`
        for List3 in `echo $SharedMemList`
        do
            ipcrm -m $List3
        done
fi

rm $MON_LOG_DIR/app/.Data* 2>/dev/null
rm $MON_LOG_DIR/app/ api_* 2>/dev/null
rm $MON_LOG_DIR/app/ mro_* 2>/dev/null
rm $MON_XML_DIR/mro_addresses* 2>/dev/null

