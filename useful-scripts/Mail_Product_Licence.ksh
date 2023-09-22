#!/bin/ksh -u
##################################### INIT  SECTION ###############################
# NAME        : Mail_Product_Licence.ksh
# DESCRIPTION : Check product licence expiration date and send email to Infra team 
#               with the results.
#
#               The script perform following:
#               - Get input and check validity 
#               - Run the Check product licence expiration date
#               - Send email to the Infra team accoring to result. 
#
# USAGE       : Mail_Product_Licence.ksh <Product>
#
# DATE        : 15-JUL-2012
# BY          : Eitan Corech
######################################################################################


###################### Customization Area - Start ######################

ACCOUNT=BSS

WORKING_AREA=/bssxpinas/bss/tooladm/Scripts/License_Checker

EMAIL_ADDR_FROM="slavikl@amdocs.com"
EMAIL_ADDR_TO="slavikl@int.amdocs.com"

###################### Customization Area - End   ######################

alias echo='echo -e'

if [[ $# -lt 1 ]]
    then
     echo "\n\n\tUsage  : `basename $0` <Product>\n"
     echo "\tSample : `basename $0` AMSS \n"
     exit 1
fi

PRODUCT=`echo $1 | tr '[:lower:]' '[:upper:]'`

if [ "${PRODUCT}" != "AMSS" ] && [ "${PRODUCT}" != "EPC" ]
then

     echo "\n\n\tERROR: \n" 
     echo "\t   Script `basename $0` is not support the licence expiration date of product ${PRODUCT}.\n"
     echo "\t   Script is currently supporting product AMSS and EPC\n"
     echo "\t   Exiting.....\n\n"
     exit 1
fi

STATUS_FILE=${WORKING_AREA}/${PRODUCT}_Lic_Status_File

SUBJECT_OK="${ACCOUNT} - ${PRODUCT} License report: All ENV are OK"
SUBJECT_NOTOK="${ACCOUNT} - ${PRODUCT} License report : There is a problem"

rm -rf $STATUS_FILE

. ${WORKING_AREA}/Product_Licence_Batch.ksh $PRODUCT

Problem_IND=`grep -i PROBLEM  ${STATUS_FILE} `

if [ "${Problem_IND}" = "" ]
then
     EMAIL_SUBJECT=$SUBJECT_OK
else
     EMAIL_SUBJECT=$SUBJECT_NOTOK     
fi

/bin/mail -s "${EMAIL_SUBJECT}" "${EMAIL_ADDR_TO}" -- -r "${EMAIL_ADDR_FROM}"   < $STATUS_FILE

exit 0
