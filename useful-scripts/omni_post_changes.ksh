#!/bin/ksh

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

echo "/vivnas/viv/vivtools/Scripts/OMNI_Scripts/PIL1_ALL_all_UpdateASCFiles_ksh ${HOME}/config/LS/ASC/CM1_root.conf /vivnas/viv/vivtools/Scripts/OMNI_Scripts/omni_post_changes_property xpiUserCM1_root"
/vivnas/viv/vivtools/Scripts/OMNI_Scripts/PIL1_ALL_all_UpdateASCFiles_ksh ${HOME}/config/LS/ASC/CM1_root.conf /vivnas/viv/vivtools/Scripts/OMNI_Scripts/omni_post_changes_property xpiUserCM1_root
