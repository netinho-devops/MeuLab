#!/usr/bin/ksh
###################################
# Author: Rajkumar Nayeni
# Pupose: Export the UAMS
#
#####################################

mkdir -p ${HOME}/UAMS_EXPORT
cd ${HOME}/UAMS_EXPORT
echo "WL9_DISABLED=1" > uams.properties
java -Damdocs.system.home=${HOME}/UAMS_EXPORT -DSEC_DB_INST=${ORACLE_SID} -DSEC_DB_PORT=1521 -DSEC_DB_USER=${SEC_ORA_USER} -DSEC_DB_PWD=${SEC_ORA_PASS} -DSEC_DB_HOST=${_OP_ORA_HOST} -Damdocs.uams.config.resource=res/gen/export -classpath ${HOME}/abp_home/storage/AMC/core/lib/uams.jar:$ORACLE_HOME/jdbc/lib/ojdbc6.jar amdocs.uamstools.UamsObjectsExporter


