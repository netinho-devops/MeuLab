#!/bin/ksh

echo "crm.clr.db.server=$1"
crm_clr_db_server=$1
echo "crm.db.port=$2"
crm_db_port=$2
echo "crm.target.db.user=$3"
crm_target_db_user=$3
echo "crm.target.db.password=$4"
crm_target_db_password=$4
echo "crm.db.instance=$5"
crm_db_instance=$5

BKP_DIR=~/config/LS/ASC_BKP_`date '+%d_%m_%Y_%H_%M'`

mkdir $BKP_DIR

cp -r ~/config/LS/ASC/* $BKP_DIR

cd ~/config/LS/ASC;

echo "sed -i 's/CommerceCareBasic;BillingCareBasic;CustomerProblemBasic/CommerceCareBasic;BillingCareBasic;CustomerProblemBasic;CommerceCareAdvanced/g' UXF_LVL_0.conf;"
sed -i 's/CommerceCareBasic;BillingCareBasic;CustomerProblemBasic/CommerceCareBasic;BillingCareBasic;CustomerProblemBasic;CommerceCareAdvanced/g' UXF_LVL_0.conf;

#echo "sed -i '/<\/Security>/i"
#sed -i '/<\/Security>/i \
#	<ExcludedURLs ID="1ca9d049f8386c3c"> \
#       <ExcludedURLPatterns ID="d4714c92ffd694da">\/.*<\/ExcludedURLPatterns> \
#	<\/ExcludedURLs>' xpiUserCM1_root.conf

cp /vivnas/viv/vivtools/Scripts/OMNI_Scripts/omni_post_changes_property ~

echo "/UXFCore/Aif/Connection/DatabaseUrl=jdbc:oracle:thin:@${crm_clr_db_server}:${crm_db_port}:${crm_db_instance}" >> ~/omni_post_changes_property
echo "/UXFCore/Aif/Connection/UserName=${crm_target_db_user}" >> ~/omni_post_changes_property
echo "/UXFCore/Aif/Connection/Password=${crm_target_db_password}" >> ~/omni_post_changes_property

echo "omni_post_changes_property:"
cat ~/omni_post_changes_property

echo "/vivnas/viv/vivtools/Scripts/OMNI_Scripts/PIL1_ALL_all_UpdateASCFiles_ksh ${HOME}/config/LS/ASC/CM1_root.conf ~/omni_post_changes_property xpiUserCM1_root"
/vivnas/viv/vivtools/Scripts/OMNI_Scripts/PIL1_ALL_all_UpdateASCFiles_ksh ${HOME}/config/LS/ASC/CM1_root.conf ~/omni_post_changes_property xpiUserCM1_root
