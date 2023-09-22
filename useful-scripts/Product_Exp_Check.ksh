#!/bin/ksh -u
##################################### INIT  SECTION ###############################
# NAME        : Produsct_Exp_Check.ksh
# DESCRIPTION : Check product licence expiration date and write result in a staus 
#               file 
#
#               The script perform following:
#               - Get input and check validity 
#               - Check the current date
#               - check the JKS expration date
#               - Write result in a status file that will be send to the Infra team
#
# USAGE       : Product_Exp_Check.ksh <Product> <Env> 
#
# DATE        : 15-JUL-2012
# BY          : Eitan Corech
######################################################################################

###################### Customization Area - Start ######################

THRESHOLD_DAYS=45
WORKING_AREA=/bssxpinas/bss/tooladm/Scripts/License_Checker

###################### Customization Area - End ######################


alias echo='echo -e'

if [[ $# -lt 2 ]]
    then
     echo "\n\n\tUsage  : `basename $0` <Product> <Env>\n"
     echo "\tSample : `basename $0` AMSS vfnams1@illin645\n"
     exit 1
fi

PRODUCT=`echo $1 | tr '[:lower:]' '[:upper:]'`

if [ "${PRODUCT}" != "AMSS" ] && [ "${PRODUCT}" != "EPC" ]
then

     echo "\n\n\tERROR: \n" 
     echo "\t   Script `basename $0` is not support the licence expiration date check of product ${PRODUCT}.\n"
     echo "\t   Script is currently supporting product AMSS or EPC\n"
     echo "\t   Exiting.....\n\n"
     exit 1
fi

UsR=`echo $2 | cut -f1 -d"@"`
Hst=`echo $2 | cut -f2 -d"@"`

EXP_FILE=$WORKING_AREA/Exp${PRODUCT}.tmp
KEY_SATRING=custom-identity-key-store-file-name
LIC_STATUS_FILE=${WORKING_AREA}/${PRODUCT}_Lic_Status_File

KEY_ALIAS=epckey
KEY_PASSWORD=Unix11

if [ "${PRODUCT}" = "AMSS" ]
then
   ssh ${UsR}@${Hst} ". ./.profile 1>/dev/null 2>&1 ; echo "\${HOME}/\${AMSS_CORE_JEE_HOME}/WLS/AMSSFullDomain/config/config.xml" ; " > $WORKING_AREA/temp.file
else
   ssh ${UsR}@${Hst} ". ./.profile 1>/dev/null 2>&1 ; echo "\${EPC_HOME_DIR}/config/config.xml" ; " > $WORKING_AREA/temp.file
fi

CONFIG_FILE=`cat $WORKING_AREA/temp.file` ; rm -rf $WORKING_AREA/temp.file
PROD_EXP_DATE="\$JAVA_HOME/bin/keytool -list -v -keystore \`grep ${KEY_SATRING} ${CONFIG_FILE} | cut -d'>' -f2 | cut -d'<' -f1\` -alias ${KEY_ALIAS} -storepass $KEY_PASSWORD" 

##################################################
# Getting the expiration date at the keystore file
##################################################

ssh ${UsR}@${Hst} ". ./.profile 1>/dev/null 2>&1; $PROD_EXP_DATE | grep Valid | grep -i until" > ${EXP_FILE}

#############################################################
# Converting date from java 1.5 format
#############################################################

Checking=`head -1 ${EXP_FILE}`

DAY=`echo ${Checking} | awk '{print $12}'`
MONTH=`echo ${Checking} | awk '{print $11}'`
YEAR=`echo ${Checking} | awk '{print $15}'`

EXPIRATION_DATE=`/bin/date +%s -d "${DAY}-${MONTH}-${YEAR}"`
CURRENT_DATE=`/bin/date "+%s"`

((DIFF_SEC=EXPIRATION_DATE-CURRENT_DATE))
((DIFF_DAYS=DIFF_SEC/(60*60*24)))

if [[ ${DIFF_DAYS} -lt ${THRESHOLD_DAYS} ]];
then
	echo "Problem ${PRODUCT} Environment ${UsR} On Server ${Hst} exipiring on ${DAY}-${MONTH}-${YEAR} Days_Left=${DIFF_DAYS}\n" >> ${LIC_STATUS_FILE}
else
	echo "Working ${PRODUCT} Environment ${UsR} On Server ${Hst} exipiring on ${DAY}-${MONTH}-${YEAR} Days_Left=${DIFF_DAYS}\n" >> ${LIC_STATUS_FILE}
fi

return 0
