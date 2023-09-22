#!/bin/ksh
#MENU_DESCRIPTION=Change application to use LOGICALDATE (run it on ABP and OMS account)
#################################################
# Name: change2logicaldate.ksh
#
# Change property files for ABP, CRM and OMS
# to make product work with Logical Date 	
# This script needs to be executed on each work account.
# It will automatically detect the product and proceed
# with changes in 
#
# Programmer: Antonio Ideguchi (hantonio)
#################################################

DATE=$1

if [[ $DATE = [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ]]
then
	LOGICAL_DATE=`/bin/date +"%d/%m/%Y" -d $DATE` 2> /dev/null
	if [[ $LOGICAL_DATE = 1 ]]
	then
		"Invalid Date! Date needs to be in the form YYYY-MM-DD!"
		exit 1
	fi
else 
    echo "Logical date needs to be in the form YYYY-MM-DD!"
	echo "Usage: $0 YYYY-MM-DD"
	exit 1
fi

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "\nSetting LOGICAL DATE as: ${LOGICAL_DATE}\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
DATE=`/bin/date '+%d%m%Y'`

if [[ $USER == *"abp"* ]]
then
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "Changing ABP configuration files to work with LOGICAL DATE..."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/CM1Environment.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_logicaldate 's/amdocs.cm.testMode=.*/amdocs.cm.testMode=Y/g' "$FILE"
        sed -i 's/amdocs.csm3g.LogicalRunDateInd=.*/amdocs.csm3g.LogicalRunDateInd=Y/g' "$FILE"
        sed -i 's/amdocs.cm.singleDateValidation=.*/amdocs.cm.singleDateValidation=Y/g' "$FILE"
        sed -i 's,amdocs.cm.dateDeltaBefore=.*,amdocs.cm.dateDeltaBefore=24h,g' "$FILE"
        sed -i 's,amdocs.cm.dateDeltaAfter=.*,amdocs.cm.dateDeltaAfter=24h,g' "$FILE"
    else
		echo "File do not exist at ${FILE}."
		exit 1
    fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/MMO1App.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
        sed -i.b4_${DATE}_logicaldate 's/amdocs.mo.LogicalRunDateInd=.*/amdocs.mo.LogicalRunDateInd=Y/g' "$FILE"
    else
        echo "File do not exist at ${FILE}."
        exit 1
    fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/CM1JF.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_logicaldate 's/amdocs.jf.app.logicaldate.userealtime.ind=.*/amdocs.jf.app.logicaldate.userealtime.ind=N/g' "$FILE"
    else
		echo "File do not exist at ${FILE}."
        exit 1
    fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/RM1JF.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_logicaldate 's/amdocs.jf.app.logicaldate.userealtime.ind=.*/amdocs.jf.app.logicaldate.userealtime.ind=N/g' "$FILE"
    else
		echo "File do not exist at ${FILE}."
		exit 1
    fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/RM1App.properties
    if [[ -f $FILE ]]
    then
        sed -i.b4_${DATE}_logicaldate 's/amdocs.rm.testMode=.*/amdocs.rm.testMode=Y/g' "$FILE"
        sed -i 's/amdocs.rm.LogicalRunDateInd=.*/amdocs.rm.LogicalRunDateInd=Y/g' "$FILE"
    else
        echo "File do not exist at ${FILE}."
        exit 1
    fi

    FILE=~/JSE/repository/area.1/modules/CM/dynamic/CM1Environment.properties
    if [[ -f $FILE ]]
    then
        sed -i.b4_${DATE}_logicaldate 's/amdocs.cm.testMode=.*/amdocs.cm.testMode=Y/g' "$FILE"
        sed -i 's/amdocs.csm3g.LogicalRunDateInd=.*/amdocs.csm3g.LogicalRunDateInd=Y/g' "$FILE"
    else
        echo "File do not exist at ${FILE}."
    fi

    FILE=~/JSE/repository/area.1/modules/RM/dynamic/RM1App.properties
    if [[ -f $FILE ]]
    then
        sed -i.b4_${DATE}_logicaldate 's/amdocs.rm.testMode=.*/amdocs.rm.testMode=Y/g' "$FILE"
        sed -i 's/amdocs.rm.LogicalRunDateInd=.*/amdocs.rm.LogicalRunDateInd=Y/g' "$FILE"
    else
        echo "File do not exist at ${FILE}."
    fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/CCS1App.properties
    if [[ -f $FILE ]]
    then
        sed -i.b4_${DATE}_logicaldate 's/amdocs.ccs.enableLogicalRunDate=.*/amdocs.ccs.enableLogicalRunDate=Y/g' "$FILE"
        sed -i 's/amdocs.ccs.LogicalRunDateInd=.*/amdocs.ccs.LogicalRunDateInd=Y/g' "$FILE"
    else
        echo "File do not exist at ${FILE}."
    fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/PC1JF.properties
    if [[ -f $FILE ]]
    then
        sed -i.b4_${DATE}_logicaldate 's/amdocs.pc.dmm.mappingengine.useLogicalDate=.*/amdocs.pc.dmm.mappingengine.useLogicalDate=Y/g' "$FILE"
    else
        echo "File do not exist at ${FILE}."
    fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/AR1JF.properties
    if [[ -f $FILE ]]
    then
        sed -i.b4_${DATE}_logicaldate 's/amdocs.ar.LogicalRunDateInd=.*/amdocs.ar.LogicalRunDateInd=Y/g' "$FILE"
    else
        echo "File do not exist at ${FILE}."
    fi

    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "Updating ABP APP database with new LOGICAL_DATE..."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

	echo "UPDATE LOGICAL_DATE SET LOGICAL_DATE = TO_DATE('${LOGICAL_DATE}', 'DD/MM/YYYY') WHERE EXPIRATION_DATE IS NULL;" | sqlplus $APP_DB_USER/$APP_DB_PASS@$APP_DB_INST

    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "Configuration concluded for ABP. Please check CRM and OMS."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    exit 0;
fi

#if [[ $USER == *"crm"* ]]
#then
#    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
#    echo "Changing CRM configuration files to work with LOGICAL DATE..."
#    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

#    FILE=~/config/ASC/CRM1_cust3CrmConfig.conf
#    echo "Changing configuration at ${FILE}..."
#    if [[ -f $FILE ]]
#	then
#		sed -i.b4_${DATE}_logicaldate '/<LD_TestingMode.*>/,/<\/LD_TestingMode>/s/<!--//;/<LD_TestingMode.*>/,/<\/LD_TestingMode>/s/-->//' "$FILE"
#    else
#		echo "File do not exist at ${FILE}."
#		exit 1
#   fi

#    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
#    echo "Configuration concluded for CRM. Please check ABP and OMS."
#    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

#    exit 0;
#fi

if [[ $USER == *"oms"* ]]
then
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "Changing OMS configuration files to work with LOGICAL DATE..."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    FILE=~/config/asc/xpiUserOMS1_root.conf
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
	then	
		#sed -i.b4_${DATE}_logicaldate '/<OMS_ABP_Connector_Initializer.*>/,/<\/OMS_ABP_Connector_Initializer>/ s|false|true|g' "$FILE"
        sed -i.b4_${DATE}_logicaldate 's/useCurrentUnixSystemDate/useBillingLogicalDate/g' "$FILE"
        sed -i 's,false</useLogicalDate>,true</useLogicalDate>,g' "$FILE"
    else
		echo "File do not exist at ${FILE}."
		exit 1
    fi

    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "Configuration concluded for OMS. Please check ABP and CRM."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    exit 0;
fi

    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "There is no need to change anything here. Please check ABP, CRM and OMS."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

exit 0;

