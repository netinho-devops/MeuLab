#!/bin/ksh
##############################################################
# Name:         checkBundle                                  #
# Programmer:   Willian Costa                                #
# Date:         12/13/2016                                   #
# Purpose:      Script to easily check a HF Bundle content   #
#                                                            #
# Changes History                                            #
# ---------------------------------------------------------- #
# Date       |   By          |  Description                  #
# -----------+---------------+------------------------------ #
# 12/13/2016 | Willian C     | First version                 #
#                                                            #
##############################################################


usage(){
    printf "Usage: checkBundle.ksh BUNDLE_NAME\n"
}

BUNDLE_NAME=$1

checkParams(){
    if [ -z ${BUNDLE_NAME} ]; then
        usage
        exit 1
    fi
}

main(){
    print "
    WHENEVER SQLERROR EXIT 5
    SET FEEDBACK OFF
    SET HEADING ON
    SET PAGES 2000
    SET LINES 200
    SET LINESIZE 4000
    SET TRIMSPOOL ON
    SET TRIMOUT ON
    COLUMN product format a4
    COLUMN order_num format 999

    SELECT b.UNIQUE_ID, m.PRODUCT, b.ORDER_NUM, m.FIX_TYPE
    FROM HOTFIX_BUNDLES b INNER JOIN HOTFIX_MNG m ON b.UNIQUE_ID = m.UNIQUE_ID
    WHERE b.BUNDLE_NAME LIKE '${BUNDLE_NAME}' ORDER BY ORDER_NUM;" | sqlplus -S tooladm/tooladm@VV9TOOLS
}

checkParams
main

exit 0
