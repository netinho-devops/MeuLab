#!/bin/ksh
#------------------------------------------------------------------------------#
# 		Script to add the security roles under Asmsa1
#------------------------------------------------------------------------------#

readlink -f ~/.profile
if [ $? -eq 0 ] 
then
        echo "profile is present"
        . ~/.profile 1>/dev/null 2>/dev/null
else
        echo "profile is not present"
        export ORACLE_HOME=`ls -A1 ~oracle/*/bin/sqlplus | grep -v 32 | tail -1 | awk -F "/bin/sqlplus" '{print $1}'`
        export JAVA_HOME=`ls -A1 /usr/java/jdk*/bin/java | grep -v 32 | tail -1 | awk -F "/bin/java" '{print $1}'`
        export PATH=${JAVA_HOME}/bin:${ORACLE_HOME}/bin:${PATH}
fi
        echo "ORACLE_HOME=$ORACLE_HOME"
	echo "JAVA_HOME=$JAVA_HOME"
	echo "PATH=$PATH"
	echo "cd ${HOME}/UAMS/Importer/"
	cd ${HOME}/UAMS/Importer/
	echo "cp abi_asm_objects_crm.xml abi_asm_objects_crm.xml_orig"
	cp abi_asm_objects_crm.xml abi_asm_objects_crm.xml_orig
	echo "cp ${HOME}/UAMS/uams.properties ${HOME}/UAMS/uams.properties_orig"
	cp ${HOME}/UAMS/uams.properties ${HOME}/UAMS/uams.properties_orig
	echo "sed -i 's#OBJ_IMPORTER_DELETE_FIRST=.*#OBJ_IMPORTER_DELETE_FIRST=true#g' ${HOME}/UAMS/uams.properties"
	sed -i "s#OBJ_IMPORTER_DELETE_FIRST=.*#OBJ_IMPORTER_DELETE_FIRST=true#g" ${HOME}/UAMS/uams.properties
	echo "sed '/<objName>Asmsa1.*/,/<\/attributeList>/{/<key>roles.*/,/<value.*/{s/<\/value>/,CommerceCareAdvanced,BillingCareAdvanced<\/value>/g}}' < abi_asm_objects_crm.xml_orig > abi_asm_objects_crm.xml"
	sed '/<objName>Asmsa1.*/,/<\/attributeList>/{/<key>roles.*/,/<value.*/{s/<\/value>/,CommerceCareAdvanced,BillingCareAdvanced<\/value>/g}}' < abi_asm_objects_crm.xml_orig > abi_asm_objects_crm.xml
	
	echo "Running ~/abp_home/core/bin/ABI1_SecObjectImporter.ksh"
	~/abp_home/core/bin/ABI1_SecObjectImporter.ksh
	echo "sed -i 's#OBJ_IMPORTER_DELETE_FIRST=.*#OBJ_IMPORTER_DELETE_FIRST=false#g' ${HOME}/UAMS/uams.properties"
	sed -i "s#OBJ_IMPORTER_DELETE_FIRST=.*#OBJ_IMPORTER_DELETE_FIRST=false#g" ${HOME}/UAMS/uams.properties
