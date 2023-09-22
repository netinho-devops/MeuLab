#!/bin/ksh
#===============================================================
# NAME      :  GetStoragePath.ksh
# Programmer:  Antonio Ideguchi
# Date      :  
# Purpose   :  Query Genesis DB and retrieve Storage Path
#
# Changes history:
#
#  Date     |     By        | Changes/New features
# ----------+---------------+-----------------------------------
#            Antonio Ideguchi       Initial version
#===============================================================

###########################################
#	INPUT PARAMETERS
###########################################

_PRODUCT=$1
_SWPNUMBER=$2
_VERSION=$3

if [ $# -lt 3 ]
then
	print "Usage: $0 <PRODUCT> <VERSION> <BUILD_NUM>"
	exit 1;
fi

## Check if arguments are numeric
re='^[0-9]+$'
if ! [[ $_SWPNUMBER =~ $re ]]; then
	echo "ERROR: Swap Number is not a number or not valid" >&2; exit 1;
fi
if ! [[ $_VERSION =~ $re ]]; then
	echo "ERROR: Version Number is not a number or not valid" >&2; exit 1;
fi

############################################
#       MAIN
############################################

BASE_PATH=$(dirname $0)

# Import profile
if [ -f $ {HOME}/.profile ]
then
	. $ {HOME}/.profile > /dev/null 2>&1
fi

case $_PRODUCT in
"AMSS"|"ABP"|"CRM"|"OMNI"|"OMS"|"SLRAMS"|"SLROMS"|"WSF")
	PRODUCT_ID=$(echo -e "set pages 0\n set pagesize 0\n set head off\n set feed off\n set verify off\n set echo off\n set trimspool on\n set termout off\n select PRODUCT_ID from GNS_PRODUCT where EXTERNAL_PRODUCT_NAME='$_PRODUCT';" | sqlplus -s tooladm/tooladm@indlin3554/vv9tools)
	VERSION_ID=$(echo -e "set pages 0\n set pagesize 0\n set head off\n set feed off\n set verify off\n set echo off\n set trimspool on\n set termout off\n select VERSION_ID from GNS_VERSION where VERSION_NUMBER='$_VERSION';"  | sqlplus -s tooladm/tooladm@indlin3554/vv9tools)
	if [[ -z "$PRODUCT_ID" ]];
	then
		echo "ERROR: No Product nor Version found on Genesis DB" >&2;
		exit 1;
	fi
	if [[ -z "$VERSION_ID" ]];
	then
		echo "ERROR: No Version found on Genesis DB" >&2;
		exit 1;
	fi
	BUILD_NUM=$(echo -e "set pages 0\n set pagesize 0\n set head off\n set feed off\n set verify off\n set echo off\n set trimspool on\n set termout off\n select BUILD_NUMBER from GNS_LOGICAL_BUILD_NUMBER where VERSION_ID=${VERSION_ID} and LOGICAL_BUILD_NUMBER=${_SWPNUMBER} and PRODUCT_ID=${PRODUCT_ID};" | sqlplus -s tooladm/tooladm@indlin3554/vv9tools)
	if [[ -z "$BUILD_NUM" ]];
	then
		echo "ERROR: No Build Number found on Genesis DB" >&2;
		exit 1;
	fi

	STORAGE=ST_${_PRODUCT}_V${_VERSION}_B${BUILD_NUM}
	STORAGE=$(echo $STORAGE | sed -e 's/ //g')
	echo $STORAGE
	;;
*)  
	print "ERROR: Invalid parameter(s).\n " | tee -a $LOG_FILE;
    print "Usage: $0 <PRODUCT> <VERSION> <BUILD_NUM>"
	exit 1;
	;;
esac

exit 0;
