#!/usr/bin/ksh
#################################
# Author: Rajkumar Nayeni
# Purpose: Import users and roles 
#   by using exported by using export script
################################
cd ${HOME}
ImportFile=''
for i in `find UAMS_EXPORT -name 'export_*USER_*.xml'`
do
		ImportFile="${ImportFile},${HOME}/${i}"
done
for i in `find UAMS_EXPORT -name 'export_*ROLE_*.xml'`
do
		ImportFile="${ImportFile},${HOME}/${i}"
done
echo ${ImportFile}
cd ${HOME}/UAMS_EXPORT
java -Damdocs.system.home=${HOME}/UAMS_EXPORT -DSEC_DB_INST=${ORACLE_SID} -DSEC_DB_PORT=1521 -DSEC_DB_USER=${SEC_ORA_USER} -DSEC_DB_PWD=${SEC_ORA_PASS} -DSEC_DB_HOST=${_OP_ORA_HOST} -Damdocs.uams.config.resource=res/gen/import -DOBJ_IMPORTER_XML_FILE=${ImportFile} -classpath ${HOME}/abp_home/storage/AMC/core/lib/uams.jar:$ORACLE_HOME/jdbc/lib/ojdbc6.jar amdocs.uamstools.UamsObjectsImporter

