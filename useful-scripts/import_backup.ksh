#!/bin/ksh



####################################################################
# TRUNCATE TABLES                                                  #
####################################################################

Truncate_tables() {

echo "Truncating tables data"

Truncate_file=/tmp/Truncate_${HOTFIX_DB_USER}_${HOTFIX_ID}_${DateStamp}

echo "connect to ${HOTFIX_DB_USER}/${HOTFIX_DB_PASS}@${HOTFIX_DB_INST}"

cat ${TABLESLIST} | tr '' '\n'  | awk '{printf("TRUNCATE TABLE %s;\n",$1)}' > ${Truncate_file}.sql


run=`
echo " spool ${Truncate_file}_Out.log
                @${Truncate_file}.sql;
                spool off;
exit;
"| sqlplus -s ${HOTFIX_DB_USER}/${HOTFIX_DB_PASS}@${HOTFIX_DB_INST}`

grep "ORA-" ${Truncate_file}_Out.log

if [ $? -eq 0 ]
then
        echo "ERROR: Unable to TRUNCATE all  Tables - There are errors in the log file ${Truncate_file}_Out.log."
        cat ${Truncate_file}_Out.log |grep "ORA-"
        Enable_FKs
        Enable_Triggers
        exit 1
else

                echo "All tables truncated successfully."

fi

}

####################################################################
# Disable FK's                                                     #
####################################################################

Disable_FKs() {

echo "Disabling all FKs in ${HOTFIX_DB_USER}@${HOTFIX_DB_INST}"

run=`
echo "
BEGIN
FOR I IN (SELECT TABLE_NAME,CONSTRAINT_NAME FROM user_constraints where CONSTRAINT_TYPE = 'R' ) LOOP
BEGIN
   EXECUTE IMMEDIATE 'alter table '||I.TABLE_NAME||' disable constraint '||I.CONSTRAINT_NAME||'';
    EXCEPTION
     WHEN OTHERS THEN NULL;
END;
END LOOP;
END;
/

exit;
"| sqlplus -s ${HOTFIX_DB_USER}/${HOTFIX_DB_PASS}@${HOTFIX_DB_INST}`

}

####################################################################
# Enable FK's                                                      #
####################################################################

Enable_FKs() {

echo "Enabling all FKs in ${HOTFIX_DB_USER}@${HOTFIX_DB_INST}"


run=`
echo "
BEGIN
FOR I IN (SELECT TABLE_NAME,CONSTRAINT_NAME FROM user_constraints where CONSTRAINT_TYPE = 'R' ) LOOP
BEGIN
   EXECUTE IMMEDIATE 'alter table '||I.TABLE_NAME||' enable constraint '||I.CONSTRAINT_NAME||'';
    EXCEPTION
     WHEN OTHERS THEN NULL;
END;
END LOOP;
END;
/

exit;
"| sqlplus -s ${HOTFIX_DB_USER}/${HOTFIX_DB_PASS}@${HOTFIX_DB_INST}`

}

####################################################################
# Enable Triggers                                                  #
####################################################################

Enable_Triggers() {

echo "Enabling all Triggers in ${HOTFIX_DB_USER}@${HOTFIX_DB_INST}"


run=`
echo "
BEGIN
FOR I IN (SELECT TRIGGER_NAME FROM user_triggers ) LOOP
BEGIN
   EXECUTE IMMEDIATE 'alter trigger '||I.TRIGGER_NAME||' enable';
    EXCEPTION
     WHEN OTHERS THEN NULL;
END;
END LOOP;
END;
/

exit;
"| sqlplus -s ${HOTFIX_DB_USER}/${HOTFIX_DB_PASS}@${HOTFIX_DB_INST}`

}


####################################################################
# Disable Triggers                                                 #
####################################################################

Disable_Triggers() {

echo "Disabling all Trigges in ${HOTFIX_DB_USER}@${HOTFIX_DB_INST}"


run=`
echo "
BEGIN
FOR I IN (SELECT TRIGGER_NAME FROM user_triggers ) LOOP
BEGIN
   EXECUTE IMMEDIATE 'alter trigger '||I.TRIGGER_NAME||' disable';
    EXCEPTION
     WHEN OTHERS THEN NULL;
END;
END LOOP;
END;
/

exit;
"| sqlplus -s ${HOTFIX_DB_USER}/${HOTFIX_DB_PASS}@${HOTFIX_DB_INST}`

}


####################################################################
# Create tables list intersection between dump and physical tables #
####################################################################

Create_Tables_List() {

Dump_Tables=/tmp/Dump_Tables_HF_${HOTFIX_ID}_${DateStamp}.lst
TEMP_PHYSICAL_TABLES=/tmp/Temp_Physical_Tables_${HOTFIX_ID}_${DateStamp}.lst
PHYSICAL_TABLES=/tmp/Physical_tables_${HOTFIX_DB_USER}_${HOTFIX_ID}_${DateStamp}.lst
TABLESLIST=/tmp/Tables_List_${HOTFIX_DB_USER}_HF_${HOTFIX_ID}_${DateStamp}.lst

perl -ne 'BEGIN {$/ = "\0"} while (/([\040-\176\s]{4,})/g) {print $1, "\n";}' ${DMP_FILE} | cut -c1-150 | grep "CREATE TABLE \"" | cut -d " " -f3 | sed -e s/\"//g | sort > ${Dump_Tables}

if [ $? -ne 0 ]
then
        export PERLERROR=`perl -ne 'BEGIN {$/ = "\0"} while (/([\040-\176\s]{4,})/g) {print $1, "\n";}' ${DMP_FILE} 2>&1`
    echo "ERROR: The following error was occured when running perl:\n$PERLERROR"
    exit 1;
fi

ChkIfFileExists ${Dump_Tables} >/dev/null

if [ $? -ne 0 ]
then
    echo "ERROR: Dump file <$DMP_FILE> doesn't contains any tables declaration."
    rm -f ${Dump_Tables}
    exit 1
fi


print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        connect ${HOTFIX_DB_USER}/${HOTFIX_DB_PASS}@${HOTFIX_DB_INST}\n
        SELECT
                TABLE_NAME
        FROM
                USER_TABLES
        ORDER BY 1;
        " | sqlplus -s /nolog > ${TEMP_PHYSICAL_TABLES}

if [ $? -ne 0 ]
then
     echo "ERROR:Failed to create physical tables list in ${PHYSICAL_TABLES}"

     exit 1
fi

cat  ${TEMP_PHYSICAL_TABLES} | sort > ${PHYSICAL_TABLES}

rm -f ${TEMP_PHYSICAL_TABLES}

comm -12 ${PHYSICAL_TABLES} ${Dump_Tables} > ${TABLESLIST}

rm -rf ${PHYSICAL_TABLES}
rm -rf ${Dump_Tables}

ChkIfFileExists ${TABLESLIST} >/dev/null

if [ $? -ne 0 ]
then
    echo " No tables in intersection between tables list in dump file and DB tables list. Exiting..."
    rm -f  ${DMPTABLIST} ${TABLESLIST} ${PHYSICAL_TABLES} ${TEMP_PHYSICAL_TABLES}

    exit 1;
fi

}

####################################################################
# Import Dump according to table list                              #
####################################################################

Import_Dump() {

echo "Starting import to ${HOTFIX_DB_USER}@${HOTFIX_DB_INST}"

Imp_Log=/tmp/Imp_log_${HOTFIX_DB_USER}_${HOTFIX_ID}_${DateStamp}.log

LINES=`wc -l ${TABLESLIST} | awk '{print $1}'`
TABLES=`cat ${TABLESLIST}  | awk -v lines=${LINES} '{printf "%s",$1 ; if ( NR < lines ) print ","}'`

echo "About to import data into accout: ${HOTFIX_DB_USER}/${HOTFIX_DB_PASS}@${HOTFIX_DB_INST} (`date '+%d-%m-%Y %H:%M:%S'`)"


${ORACLE_HOME}/bin/imp ${HOTFIX_DB_USER}/${HOTFIX_DB_PASS}@${HOTFIX_DB_INST} file=${DMP_FILE} log=${Imp_Log} tables=${TABLES} ignore=y grants=n buffer=1024000 constraints=n indexes=n

grep "Import terminated unsuccessfully" ${Imp_Log} 2>&1 >/dev/null

if [ $? = 0 ]
then
    echo "ERROR: Import terminated unsuccessfully"
    echo "For mode details log: ${Imp_Log}"
    Enable_FKs
    Enable_Triggers
    exit 1
fi



grep "Import terminated successfully with warnings" ${Imp_Log} 2>&1 >/dev/null
if [ $? = 0 ]
then
    grep "IMP-00002" ${Imp_Log} 2>&1 >/dev/null
    if [ $? = 0 ]
    then
        echo "ERROR: Import terminated unsuccessfully"
        echo "For mode details log: ${Imp_Log}"
        Enable_FKs
        Enable_Triggers
        exit 1
    else
        echo "WARNING: Import terminated successfully with warnings"

    fi
fi


echo "Import finished successfully"
echo "For mode details log: ${Imp_Log}"

}


####################################################################
# Check file existence                                             #
####################################################################

ChkIfFileExists()
{

InputFileName=$1

if [ -d "${InputFileName}" ]
then
     echo "\nERROR: ${InputFileName} is a directory. File is expected .\n"
     return 1

fi

if [ ! -s "${InputFileName}" ]
then
     echo "\nERROR: file: ${InputFileName} does not exists or empty.\n"
     return 1
fi

return 0

}


####################################################################
# MAIN                                                             #
####################################################################

if [[ $# -ne 5 ]]
then
    echo "Seems that enviroment variable are missing in the deploy environemnt" 1>&2
    echo "Please check: The variables that used in Hot-fix Deploy Methods Screen are exist in the .profile as well" 1>&2
    exit 1
fi


HOTFIX_DB_USER=$1
HOTFIX_DB_PASS=$2
HOTFIX_DB_INST=$3
DMP_FILE=$4
TRUNCATE_MODE=$5

#HOTFIX_ID=HF100651
DateStamp=`date +%y%m%d%H%M%S`


echo "connected to ${HOTFIX_DB_USER}/${HOTFIX_DB_PASS}@${HOTFIX_DB_INST}"


Create_Tables_List

Disable_FKs

Disable_Triggers

if [[ ${TRUNCATE_MODE} = "Y" ]]
then

Truncate_tables

fi

Import_Dump

Enable_FKs

Enable_Triggers
exit 0
