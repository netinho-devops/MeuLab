#!/bin/ksh -f
##################################### INIT  SECTION ###############################
# NAME        : Product_Licence_Batch.ksh
# DESCRIPTION : Check product licence expiration of a product accoding to pre-define 
#               file that hold the list of Env to check
#
#               The script perform following:
#               - Get input and check validity 
#               - Check tht the input file exits
#               - Call other script to check the expiration on each env. 
#
# USAGE       : Product_Licence_Batch.ksh <Product>
#
# DATE        : 15-JUL-2012
# BY          : Eitan Corech
######################################################################################


###################### Customization Area - Start ######################

WORKING_AREA=/bssxpinas/bss/tooladm/Scripts/License_Checker

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


ENV_LIST_FILE=${WORKING_AREA}/${PRODUCT}_Env_List

if [ -f ${ENV_LIST_FILE} ]
then
   for ENV in `cat ${ENV_LIST_FILE}`
   do
	    ${WORKING_AREA}/Product_Exp_Check.ksh ${PRODUCT} ${ENV}
   done
else
   echo "\n\n\tERROR: \n" 
   echo "\t  File ${ENV_LIST_FILE} " 
   echo "\t  with the list of the env to check the ${PRODUCT} licence is missing. \n"
   echo "\t  Create the file with the following format:\n"
   echo "\t  {Account1}@{Sever}\n\t  {Account2}@{Sever}\n\t  .....\n\t  .....\n"
   echo "\t  Insure ssh connection exist from this account "$USER" to these accounts.\n\n"
   exit 1
fi

return 0 

