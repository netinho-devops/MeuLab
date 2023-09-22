#!/bin/ksh

UNIX_HOST=`hostname`

oms_asc_prop="/vivnas/viv/vivtools/Scripts/OMNI_Scripts/oms_asc_changes.property"
omni_port=`grep -w "LISTEN_PORT=" ~/JEE/*/scripts/*/*/setenvomni*sh | cut -d "=" -f2 |tr -d '\"'`

ABP_UNIX_ACCOUNT=`echo ${USER} | cut -c 1-3`wrk`echo ${USER} | cut -c 7-20`
CRM_UNIX_ACCOUNT=`echo ${USER} | cut -c 1-3`crm`echo ${USER} | cut -c 7-20`
OMS_UNIX_ACCOUNT=`echo ${USER} | cut -c 1-3`oms`echo ${USER} | cut -c 7-20`

#OMS_EAAS_UNIX_ACCOUNT=`awk -F ":" '{print $1}' /etc/passwd | tr -d ' ' | grep -i oms | grep -iv slr`
#CRM_EAAS_UNIX_ACCOUNT=`awk -F ":" '{print $1}' /etc/passwd | tr -d ' ' | grep -i crm`

echo "/mpsnas/MPS/EAAS/scripts/create_sshlogin.ksh -u $OMS_UNIX_ACCOUNT -h ${UNIX_HOST} -p Unix11!"
/mpsnas/MPS/EAAS/scripts/create_sshlogin.ksh -u $OMS_UNIX_ACCOUNT -h ${UNIX_HOST} -p Unix11!
echo "/mpsnas/MPS/EAAS/scripts/create_sshlogin.ksh -u $CRM_UNIX_ACCOUNT -h ${UNIX_HOST} -p Unix11!"
/mpsnas/MPS/EAAS/scripts/create_sshlogin.ksh -u $CRM_UNIX_ACCOUNT -h ${UNIX_HOST} -p Unix11!
echo "/mpsnas/MPS/EAAS/scripts/create_sshlogin.ksh -u $ABP_UNIX_ACCOUNT -h ${UNIX_HOST} -p Unix11!"
/mpsnas/MPS/EAAS/scripts/create_sshlogin.ksh -u $ABP_UNIX_ACCOUNT -h ${UNIX_HOST} -p Unix11!

#sed -i "s#/Ordering/OrderingBA/LoginByTicket/URL=.*#/Ordering/OrderingBA/LoginByTicket/URL=http://${UNIX_HOST}:${omni_port}#g" $oms_asc_prop

echo "ssh ${OMS_UNIX_ACCOUNT}@${UNIX_HOST} -n '. ~/.profile 1>/dev/null 2>/dev/null;/vivnas/viv/vivtools/Scripts/OMNI_Scripts/oms_local_changes $omni_port ${UNIX_HOST}'"
ssh ${OMS_UNIX_ACCOUNT}@${UNIX_HOST} -n ". ~/.profile 1>/dev/null 2>/dev/null;/vivnas/viv/vivtools/Scripts/OMNI_Scripts/oms_local_changes $omni_port ${UNIX_HOST}"

# ssh ${CRM_UNIX_ACCOUNT}@${UNIX_HOST} "/vivnas/viv/vivtools/Scripts/OMNI_Scripts/add_sec_role.ksh"
echo "ssh ${CRM_UNIX_ACCOUNT}@${UNIX_HOST} '/vivnas/viv/vivtools/Scripts/OMNI_Scripts/crm_local_change.ksh $omni_port ${UNIX_HOST}'"
ssh ${CRM_UNIX_ACCOUNT}@${UNIX_HOST} "/vivnas/viv/vivtools/Scripts/OMNI_Scripts/crm_local_change.ksh $omni_port ${UNIX_HOST}"
echo "ssh ${ABP_UNIX_ACCOUNT}@${UNIX_HOST} '/vivnas/viv/vivtools/Scripts/OMNI_Scripts/abp_sec_role_importer.ksh'"
ssh ${ABP_UNIX_ACCOUNT}@${UNIX_HOST} -n "/vivnas/viv/vivtools/Scripts/OMNI_Scripts/abp_sec_role_importer.ksh"
