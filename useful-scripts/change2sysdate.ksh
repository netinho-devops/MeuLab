#!/bin/ksh
#MENU_DESCRIPTION=Change application to use SYSDATE (run it on ABP and OMS account)
#################################################
# Name: change2sysdate.ksh
#
# Change property files for ABP, CRM and OMS
# to make product work with Sysdate	
# This script needs to be executed on each work account.
# It will automatically detect the product and proceed
# with changes in 
#
# Programmer: Antonio Ideguchi (hantonio)
#################################################

DATE=`/bin/date '+%d%m%Y'`

if [[ $USER == *"abp"* ]]
then
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "Changing ABP configuration files to work with SYSDATE..."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/CM1Environment.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_sysdate 's/amdocs.cm.testMode=.*/amdocs.cm.testMode=N/g' "$FILE"
		sed -i 's/amdocs.csm3g.LogicalRunDateInd=.*/amdocs.csm3g.LogicalRunDateInd=N/g' "$FILE"
		sed -i 's/amdocs.cm.singleDateValidation=.*/amdocs.cm.singleDateValidation=N/g' "$FILE"
		sed -i 's,amdocs.cm.dateDeltaBefore=.*,amdocs.cm.dateDeltaBefore=15m,g' "$FILE"
		sed -i 's,amdocs.cm.dateDeltaAfter=.*,amdocs.cm.dateDeltaAfter=15m,g' "$FILE"
    else
		echo "File do not exist at ${FILE}."
		exit 1
    fi

	FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/MMO1App.properties
	echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_sysdate 's/amdocs.mo.LogicalRunDateInd=.*/amdocs.mo.LogicalRunDateInd=N/g' "$FILE"
	else
		echo "File do not exist at ${FILE}."
		exit 1
	fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/CM1JF.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_sysdate 's/amdocs.jf.app.logicaldate.userealtime.ind=.*/amdocs.jf.app.logicaldate.userealtime.ind=Y/g' "$FILE"
    else
		echo "File do not exist at ${FILE}."
        exit 1
    fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/RM1JF.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_sysdate 's/amdocs.jf.app.logicaldate.userealtime.ind=.*/amdocs.jf.app.logicaldate.userealtime.ind=Y/g' "$FILE"
    else
		echo "File do not exist at ${FILE}."
		exit 1
    fi

	FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/RM1App.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_sysdate 's/amdocs.rm.testMode=.*/amdocs.rm.testMode=N/g' "$FILE"
		sed -i 's/amdocs.rm.LogicalRunDateInd=.*/amdocs.rm.LogicalRunDateInd=N/g' "$FILE"
	else
        echo "File do not exist at ${FILE}."
        exit 1
	fi

	FILE=~/JSE/repository/area.1/modules/CM/dynamic/CM1Environment.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_sysdate 's/amdocs.cm.testMode=.*/amdocs.cm.testMode=N/g' "$FILE"
		sed -i 's/amdocs.csm3g.LogicalRunDateInd=.*/amdocs.csm3g.LogicalRunDateInd=N/g' "$FILE"
	else
		echo "File do not exist at ${FILE}."
	fi
	
	FILE=~/JSE/repository/area.1/modules/RM/dynamic/RM1App.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_sysdate 's/amdocs.rm.testMode=.*/amdocs.rm.testMode=N/g' "$FILE"
		sed -i 's/amdocs.rm.LogicalRunDateInd=.*/amdocs.rm.LogicalRunDateInd=N/g' "$FILE"
	else 
        echo "File do not exist at ${FILE}."
	fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/CCS1App.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
        sed -i.b4_${DATE}_sysdate 's/amdocs.ccs.enableLogicalRunDate=.*/amdocs.ccs.enableLogicalRunDate=N/g' "$FILE"
        sed -i 's/amdocs.ccs.LogicalRunDateInd=.*/amdocs.ccs.LogicalRunDateInd=N/g' "$FILE"
    else
        echo "File do not exist at ${FILE}."
    fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/PC1JF.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
		sed -i.b4_${DATE}_sysdate 's/amdocs.pc.dmm.mappingengine.useLogicalDate=.*/amdocs.pc.dmm.mappingengine.useLogicalDate=N/g' "$FILE"
    else
        echo "File do not exist at ${FILE}."
    fi

    FILE=~/JEE/ABPProduct/config_files/ABP-FULL/ABPServer/AR1JF.properties
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
    then
        sed -i.b4_${DATE}_sysdate 's/amdocs.ar.LogicalRunDateInd=.*/amdocs.ar.LogicalRunDateInd=N/g' "$FILE"
    else
        echo "File do not exist at ${FILE}."
    fi

    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "Configuration concluded for ABP. Please check CRM and OMS."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    exit 0;
fi

#if [[ $USER == *"crm"* ]]
#then
#    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
#    echo "Changing CRM configuration files to work with SYSDATE..."
#    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

#    FILE=~/config/ASC/CRM1_cust3CrmConfig.conf
#    echo "Changing configuration at ${FILE}..."
#    if [[ -f $FILE ]]
#	then
#        sed -i.b4_${DATE}_sysdate -n '/<LD_TestingMode.*>/,/<\/LD_TestingMode>/s/.*/<!-- & -->/q' "$FILE"
#    else
#		echo "File do not exist at ${FILE}."
#		exit 1
#    fi

#    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
#    echo "Configuration concluded for CRM. Please check ABP and OMS."
#    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

#    exit 0;
#fi

if [[ $USER == *"oms"* ]]
then
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "Changing OMS configuration files to work with SYSDATE..."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    FILE=~/config/asc/xpiUserOMS1_root.conf
    echo "Changing configuration at ${FILE}..."
    if [[ -f $FILE ]]
	then	
		#sed -i.b4_${DATE}_sysdate '/<OMS_ABP_Connector_Initializer.*>/,/<\/OMS_ABP_Connector_Initializer>/ s|true|false|g' "$FILE"
		sed -i.b4_${DATE}_sysdate 's/useBillingLogicalDate/useCurrentUnixSystemDate/g' "$FILE"
		sed -i 's,true</useLogicalDate>,false</useLogicalDate>,g' "$FILE"
    else
		echo "File do not exist at ${FILE}."
		exit 1
    fi

    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "Configuration concluded for CRM. Please check ABP and CRM."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    exit 0;
fi

    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "There is no need to change anything here. Please check ABP, CRM and OMS."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

exit 0;

