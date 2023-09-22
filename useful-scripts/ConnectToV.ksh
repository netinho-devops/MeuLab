#!/bin/ksh

PRODUCT=$1
ENV=$2
MARKET="wrk"
HOST="indlnqw"

case ${PRODUCT} in
		"sla") PRODUCT="slr" ; MARKET="ams" ;;
		"slo") PRODUCT="slr" ; MARKET="oms" ;;
esac

ssh ${PRODUCT}${MARKET}1@${HOST}${ENV}
