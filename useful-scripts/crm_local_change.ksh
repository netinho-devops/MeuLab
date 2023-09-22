#!/bin/ksh

export scriptDir=`dirname $0`
omni_port=$1
echo "omni_port=$1"
omni_host=$2
echo "omni_host=$2"


echo ". ~/.profile 1>/dev/null 2>/dev/null"
. ~/.profile 1>/dev/null 2>/dev/null

if [[ $HOST == *"eaas"* ]]
then
	EAAS_FLAG=1
	UXF_URL=:${omni_port}
else
	EAAS_FLAG=0
	UXF_URL=http://${omni_host}:${omni_port}
fi

echo
echo "#--------------------UPDATE CRM WORKSPACE--------------------#"
echo
echo "cd ${HOME}/JEE/CRMProduct/config_files/shared_config/"
cd ${HOME}/JEE/CRMProduct/config_files/shared_config/
echo "cp workspace.xml workspace.xml_orig"
cp workspace.xml workspace.xml_orig

TAG_COUNT=`grep -c UXF_HOST_BASE_URL workspace.xml`
echo "TAG_COUNT=$TAG_COUNT"
if [ $TAG_COUNT -eq 0 ]
then
	echo "Adding UXF tags in workspace.xml"
	sed -i "s#<TitleBarDisplay#<InitParam>\n<ParamName>UXF_HOST_BASE_URL</ParamName>\n<ParamValue>$UXF_URL/cm-repository-client_l9_common</ParamValue>\n<Description>Default base UXF host domain</Description>\n</InitParam>\n<InitParam>\n<ParamName>LOGINSVC_BACKEND_ID</ParamName>\n<ParamValue>crm</ParamValue>\n<Description>server back end id</Description>\n</InitParam>\n<InitParam>\n<ParamName>UxfCtxMgrListeners</ParamName>\n<ParamValue>com.amdocs.crm.uxfc.ctxmgr.listeners.AccountListener;com.amdocs.crm.uxfc.ctxmgr.listeners.AddressListener;com.amdocs.crm.uxfc.ctxmgr.listeners.BarListener;com.amdocs.crm.uxfc.ctxmgr.listeners.BillingInfoPanelListener;com.amdocs.crm.uxfc.ctxmgr.listeners.ContactListener;com.amdocs.crm.uxfc.ctxmgr.listeners.CustomerListener;com.amdocs.crm.uxfc.ctxmgr.listeners.IntrxnTopicListener;com.amdocs.crm.uxfc.ctxmgr.listeners.SiteListener;com.amdocs.crm.uxfc.ctxmgr.listeners.SitePartListener</ParamValue>\n<Description>Listeners for the CRM context manager data models.</Description>\n</InitParam>\n<InitParam>\n<ParamName>BridgeContextPolicy.BypassedTopics</ParamName>\n<ParamValue>error;security</ParamValue>\n<Description>List of topics that will always be published by the bridge context policy. Topics are separated by semi-colons.</Description>\n</InitParam>\n<InitParam>\n<ParamName>CRM_UXF_CONTEXT_ROOT</ParamName>\n<ParamValue>/cm-repository-client_l9_common/</ParamValue>\n<Description>CRM HTMLs root context</Description>\n</InitParam>\n<TitleBarDisplay#g" workspace.xml
else
	if [ `grep -c "/cm-repository-client" workspace.xml` -eq 1 ]
        then
		echo "cm-repository-client entry exists in workspace.xml, Correcting it"
                sed -i "s#>.*/cm-repository-client#>$UXF_URL/cm-repository-client#g" workspace.xml
	else
		echo "/cm-repository-client occured more than once. Please change manually"
                grep "/cm-repository-client" workspace.xml
        fi
fi

echo
echo "diff workspace.xml workspace.xml_orig"
echo
diff workspace.xml workspace.xml_orig
echo
echo "#-------------------- UPDATE CRM ASC ------------------------#"
echo
echo "cp ${scriptDir}/crm_asc_changes.property ~"
cp ${scriptDir}/crm_asc_changes.property ~
echo "sed -i 's#51000#${omni_port}#g' ~/crm_asc_changes.property"
sed -i "s#51000#${omni_port}#g" ~/crm_asc_changes.property

if [[ $EAAS_FLAG -eq 0 ]]
then
	echo "sed -i 's#eaasrt#$omni_host#g' ~/crm_asc_changes.property"
	sed -i "s#eaasrt#$omni_host#g" ~/crm_asc_changes.property
fi

BKP_DIR=~/config/ASC_`date '+%d_%m_%Y_%H_%M'`
mkdir $BKP_DIR

echo "cp -r ~/config/ASC/* $BKP_DIR"
cp -r ~/config/ASC/* $BKP_DIR

echo "cat ~/crm_asc_changes.property"
cat ~/crm_asc_changes.property

echo "JAVAHOME=$JAVA_HOME"
echo "${scriptDir}/PIL1_ALL_all_UpdateASCFiles_ksh ${HOME}/config/ASC/CRM1_root.conf ${HOME}/crm_asc_changes.property xpiUserCRM1_root"
${scriptDir}/PIL1_ALL_all_UpdateASCFiles_ksh ${HOME}/config/ASC/CRM1_root.conf ${HOME}/crm_asc_changes.property xpiUserCRM1_root
