#!/usr/bin/ksh
######################################################
# Author  : Rajkumar N
# Purpose : To get all SWP informaiton
# Usage   : SWP_Details.ksh <version> <SWP_number>
#
######################################################

showSWPITEMInfo()
{
SWPITEM=${1}
sqlplus -s $INFMATE_DB << EOF
set hea off feed off pagesize 0
select PARAM_VALUE from IMT_FLOW_INFO where PARAM_NAME like '${SWPITEM}' and FLOW_ID in (select FLOW_ID from IMT_FLOW_INFO where PARAM_NAME='SWP_VERSION' and PARAM_VALUE like '${VERSION}' and FLOW_ID in (select FLOW_ID from IMT_FLOW_INFO where PARAM_NAME='SWP_NAME' and PARAM_VALUE like '%${SWP}'));
exit;
EOF
}

VERSION=${1}
SWP=${2}
INFMATE_DB='tooladm/tooladm@VV9TOOLS'


echo -e " \n Version ${VERSION} SWP ${SWP} Information:  "

echo -e "\n \n #########################################"
echo -e " ABP Details: "
echo -e " #########################################"
echo -e " Build Number: `showSWPITEMInfo ABP_PRODUCT_BUILD_NUM` "
echo -e " Storage     : `showSWPITEMInfo ABP_STORAGE_NAME` "
echo -e " DB Patch    : `showSWPITEMInfo ABP_DB_PATCH_ID` "
echo -e " REF Dump    : `showSWPITEMInfo ABP_REF_DMP` "

echo -e "\n \n #########################################"
echo -e " CRM Details: "
echo -e " #########################################"
echo -e " Build Number: `showSWPITEMInfo CRM_PRODUCT_BUILD_NUM` "
echo -e " Storage     : `showSWPITEMInfo CRM_STORAGE_NAME` "
echo -e " DB Dump     : `showSWPITEMInfo CRM_STORAGE_NAME`/crm.dmp.gz "

echo -e "\n \n #########################################"
echo -e " OMS Details: "
echo -e " #########################################"
echo -e " Build Number: `showSWPITEMInfo OMS_PRODUCT_BUILD_NUM` "
echo -e " Storage     : `showSWPITEMInfo OMS_STORAGE_NAME` "
echo -e " DB Patch    : `showSWPITEMInfo OMS_DB_PATCH_ID` "
echo -e " BPM Dump    : `showSWPITEMInfo OMS_BPM_DMP` "
echo -e " REF Dump    : `showSWPITEMInfo OMS_REF_DMP` "
echo -e " SE REF Dump    : `showSWPITEMInfo SE_REF_DMP` "



echo -e "\n \n #########################################"
echo -e " OPX Details: "
echo -e " #########################################"
echo -e " Build Number: `showSWPITEMInfo OPX_PRODUCT_BUILD_NUM` "
echo -e " Storage     : `showSWPITEMInfo OPX_STORAGE_NAME` "


echo -e "\n \n #########################################"
echo -e " AMSS Details: "
echo -e " #########################################"
echo -e " Build Number: `showSWPITEMInfo AMSS_PRODUCT_BUILD_NUM` "
echo -e " Storage     : `showSWPITEMInfo AMSS_STORAGE_NAME` "
echo -e "\n"
