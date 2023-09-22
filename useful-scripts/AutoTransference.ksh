#!/bin/ksh
#################################################
# Name: TRANSFER_AUTO4UAT.ksh
#
# Transfer AUTO to each UAT environment
#
# Programmer: Antonio Ideguchi (hantonio)
#################################################

###########################################
#        RSYNC TRANSFER
###########################################
RSYNC_Transfer() {
        SRC=$1
        DST=$2
		DSTPATH=$3
        LOG=$4
		MODE=$5

		if [ "$MODE" == "1" ]; then
	        MKDIRCMD="mkdir -p "$DSTPATH" && rsync";
	        rsync -azvpcP --update --rsync-path="$MKDIRCMD" -e 'ssh -o "NumberOfPasswordPrompts 0"' $SRC $DST:$DSTPATH --log-file=$LOG;
		fi

		if [ "$MODE" == "2" ]; then
			rsync -azvpcP --update -e 'ssh -o "NumberOfPasswordPrompts 0"' $SRC $DST:$DSTPATH --log-file=$LOG
		fi

        if [ "$?" -ne "0" ]; then
                echo "Error in transference!"
                #exit 1;
        fi
}

###########################################
#        MAIN
###########################################

DATE=`date +"%m%d%y-%H%M"`

#sqlplus -s ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE} @retrieveSignature.sql;

LOG_FILE="/vivnas/viv/vivtools/Scripts/AutoToolBoxTransference/logs/autotransf_${DATE}.log";

while IFS='' read -r signature || [[ -n "$signature" ]]; do
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "Transferring Auto to $signature..."
	RSYNC_Transfer "auto" $signature "~/" $LOG_FILE 2
	RSYNC_Transfer "Automation/*" $signature "~/Automation" $LOG_FILE 1
	#echo "Setting permissions..."
	#ssh -q -o "BatchMode yes" $signature "chmod -R 777 ~/auto ~/Automation" || true
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
done < signatures.csv
