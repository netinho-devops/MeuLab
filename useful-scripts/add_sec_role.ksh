#!/bin/ksh

echo
echo "sec role importer's been invoked"
echo

. $HOME/.profile 2>/dev/null
cd ~/Batch/CRM/dbadmin/
CHANGED_XML="/vivnas/viv/vivtools/Scripts/OMNI_Scripts/abi_asm_objects_crm.xml"
UAMS_HOME="$HOME/JEE/CRMProduct/config_files/shared_config"

java -Dproperty.file.location=${CHANGED_XML} -Damdocs.system.home=${UAMS_HOME} -Damdocs.uams.config.resource=res/gen/import -cp .:./AmdocsSecurityManager.jar:./ojdbc6.jar:./ojdbc7.jar: amdocs.uamstools.UamsObjectsImporter
