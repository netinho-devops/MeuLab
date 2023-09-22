#!/bin/ksh
#============================================================================
# NAME   RefreshDatabase.ksh
#
# DESCRIPTION: This file performs the reference distribution structure, by doing one of the following
#              (According to the chosen Run Mode):
# 1. Combine the refresh Reference DB with the CRM schema handling
# 2. Handle CRM schema only   (running either xml file or dat files)
# 3. Refresh Reference schema only   (running release and distribute processes)
# 4. Perform Release reference only
# 5. Perform Distribute reference only
#
# ASSUMPTIONS:
# 1. SA, SACON, SAREF1 and SAREF2, already exist.
# 2. There is valid data in SA user.
# 3. The most up-to-date objectSchema.xml and x_dbtune.sql copied from the CC.
#
# This done by the following:
# 1.  Get Parameter file (ParFile.par) with needed parameters.
#     e.g. - passwords, *.dmp path, *.dat files that need to be run, whether to delete reference data, etc.
#     If the parameter file does not exist, you can get example file, you should edit it and run program again.
#
# 2. Check Parameters - Check validation of all parameters in the parameter file.
#    (e.g. - Check connections to all DB users;
#            Correct answers given to all questions;
#            Correct details given according to the answers)
#
# 3. Make sure that CRM_REF_INFO table exists. - NO NEED!!!
#
# 4. Define Active/Inactive reference users and passwords
#
# 5. If the Run Mode is 2 or 5, check that there is consistency between the control table and the synonyms.
#
# 6. If the Run Mode is 5, make sure that all reference tables exist before switching the synonyms.
#
# 7. If the Run Mode is 1 or 3 or 4, and we confirmed to delete all reference's objects (DEL_CONFIRM=Y),
#    Delete all object from the non active reference user;
#    Export the master reference (if EXP_CONFIRM=Y) or get the location of the *.dmp file (EXP_CONFIRM=N);
#    Import the *.dmp file into the reference user;
#    Run *.dat files (with dataex) on the reference user (if DAT_CONFIRM1=Y, no matter if DEL_CONFIRM is Y or N);
#    Handle UPD tables;
#    Handle special tables: table_config_itm, table_num_scheme;
#    Grant select permissions on all reference tables and remove any other permissions from CLARIFY_USER role;
#    Revoke Unnecessary Grants from all reference tables
#
# 8. If the Run Mode is 1 or 2, drop the synonyms from SA user to the reference user and rename the tables instead;
#    Run *.dat files (with dataex) on SA user (if DAT_CONFIRM2=Y);
#    Run *.xml file on SA user (if XML_CONFIRM=Y);
#    Handle New Indexes by running x_dbtune.sql;
#    Rename Reference tables from App User;
#    Drop public synonyms from App user and reference user;
#    Drop all grants to public;
#
# 9. If the Run Mode is 1 or 3 or 5, update CRM_REF_INFO table with the new reference user.
#
#10. If the Run Mode is 1 or 2 or 3 or 5, recreate synonyms from App user to the new reference user;
#    Recreate synonyms to sacon to App and the new reference user;
#    Recompile all views;
#    Recompile all other invalid objects;
#============================================================================

#-------------------------
# Prepare Parameter File
#-------------------------
Create_Par_File()
{
# USER_ANSWER=1
# CRE_CONFIRM=0
# while [ $USER_ANSWER -eq 1 ]
#   do
#    read ANS
#    case $ANS in
#      [Yy] ) USER_ANSWER=0;CRE_CONFIRM=1;;
#      [Nn] ) USER_ANSWER=0;DEL_CONFIRM=0;;
#         * ) echo " wrong choice try again (Y/N)";;
#    esac
#   done
CRE_CONFIRM=1
if [ "${CRE_CONFIRM}" = "1" ]
  then cat << !! > $PARFILE
#!/bin/ksh

#Mode of work: 1 - For handle refresh reference DB and CRM schema
#              2 - For handle CRM schema only   (running either xml file or dat files)
#              3 - For Refresh Reference schema only   (running release and distribute processes)
#              4 - For handle Release reference only
#              5 - For handle Distribute reference only
RUN_MODE=1

#instance name to work on:
PROD_INSTANCE=${ORACLE_SID}
HOST=`hostname`



APP_PWD=$APP_PWD								# SA password
CONN_PWD=$CONN_PWD							# SACON password
SAREF1_PWD=$SAREF1_PWD					# SAREF1 password
SAREF2_PWD=$SAREF2_PWD					# SAREF2 password

#Please give CC version and Build number:
VERSION_NO=$VERSION_NO
BUILD_NO=$BUILD_NO

##For RUN_MODE=1/3/4: ##
# Do You Want To Delete all Reference objects? (Y/N)
DEL_CONFIRM=Y
# Do you want to refresh reference tables from ref_tables_list.lst (Y) or all objects from dump (N)
REF_PARFILE=Y
# If DEL_CONFIRM=Y:
# Do You Want To Export the Master Reference? (Y- For Yes, N- If you already have dmp file)
EXP_CONFIRM=N
# If EXP_CONFIRM=Y, Please enter the master reference details: Instance, Username, Password:
M_INST=
M_USERNAME=
M_PASSWORD=
#If EXP_CONFIRM=N, Please give full path to the dmp file, including the file name:
EXP_PATH=Dmp/sa.dmp
#If EXP_CONFIRM=N, Please enter the DB account name of which the dmp file taken from:
FROMUSER=SA
# Do You need to Run *.dat files (with dataex) or *.sql files on the reference user? (Y/N)
DAT_CONFIRM1=N
#If DAT_CONFIRM1=Y, Please give full path to all dat/sql files separated by semicolon (;) within inverted commas ("):
# for example: DAT_PATH1="tmp/dat1.dat;tmp/dat2.dat;tmp/dat3.sql"
DAT_PATH1=

##For RUN_MODE=1/2: ##
# Do You need to Run *.dat files (with dataex) or *.sql files on App user? (Y/N)
DAT_CONFIRM2=N
#If DAT_CONFIRM2=Y, Please give full path to all dat/sql files separated by semicolon (;) within inverted commas ("):
# for example: DAT_PATH2="tmp/dat1.dat;tmp/dat2.dat;tmp/dat3.sql"
DAT_PATH2=
# Do You need to Run Schema XML? (Y/N)
XML_CONFIRM=Y

##For RUN_MODE=1/3/4: ##
MACHINEIP=`$GREP jdbc_db_server ${CBO_HOME}/bin/clarify.env | cut -d= -f2`

##For RUN_MODE=5: ##
# Are You Sure That RefreshDatabase.ksh in RUN_MODE 4 Already Run? (Y/N)
RUN_CONFIRM=N

# If DAT_CONFIRM1=Y or DAT_CONFIRM2=Y, Please give the dataex path:
#=================================================================
DATAEX_PATH=${CLARIFY_DIR}/dataex

# If XML_CONFIRM=Y, Please give the xml command:
#==============================================
# Enter \$APP_USER as username, \$APP_PWD as password, \$MACHINEIP as db_server, \$PROD_INSTANCE db_name, \$LOGDIR/trace_file.log as tracefile
DBNAME=\`echo "\${PROD_INSTANCE}"|tr [:upper:] [:lower:]\`
XML_COMMAND="java -Xms512m -Xmx512m -cp ${CLARIFY_DIR}/ClfySchemaMgr.jar com.clarify.schemamgr.SchemaMgr -user_name \$APP_USER -password \$APP_PWD -db_server \$MACHINEIP -db_name \$DBNAME -echo -debug -tracefile $LOGDIR/trace_file.log -replace ${CLARIFY_DIR}/db_schema_gen.xml "
!!
       echo " File $PARFILE created - edit it and run program again."
fi
Exit_Func
}

#----------------------------
# Set the Environment Number
#----------------------------
Env_Num()
{
export ENV_NUM=`echo ${USER}| cut -c 7-8 | $AWK '{print $1}'`

export ENV_USER=`echo $LOGNAME | cut -c 1-3 | tr '[:lower:]' '[:upper:]'`

# Defining target environment type (infra, subsystem-test, system-test):
case ${ENV_USER} in
     spr | SPR) export ENV_TYPE=SST
                ;;
     spt | SPT) export ENV_TYPE=ST
                ;;
     inf | INF) export ENV_TYPE=INF
                ;;
esac
}

#-------------------
# Exit the Program
#-------------------
Exit_Func()
{
Remove_Tmp_Files
Drop_Tab_All_Indexes
##Assign_ACL SACON
upg_status_upd

if [[ ${STATUS} = SUCCESS ]]
then
	\rm -Rf ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS
	exit 0
else
	exit 1
fi
echo "\n Exiting RefreshDatabase . . ."
}

#-------------------
# UPG_STATUS Table
#-------------------
upg_status_upd()
{
SCHEMAFILE=`echo $XML_COMMAND | $AWK -F"-replace " '{print $2}'`
TABLE_EXIST=`
echo "  set echo off head off verify off feed off pages 0 lin 100
	select TABLE_NAME from TABS where TABLE_NAME='UPG_STATUS';
	exit;
"| sqlplus -s ${APP_USER}/${APP_PWD}@${PROD_INSTANCE}`

if [[ ${TABLE_EXIST} != UPG_STATUS ]]
then
	echo "Creating UPG_STATUS table . . ."
	echo "  set echo off head off verify off feed off pages 0 lin 100
	create table UPG_STATUS  (INSTANCE varchar2(8), UPG_DATE date, VERSION varchar2(5), BUILD_NO varchar2(5), STATUS varchar2(8), RUN_MODE char(1), ACTIVE_REF varchar2(24), DUMP_NAME varchar2(256), SCHEMAFILE varchar2(256));
	exit;
  "| sqlplus -s ${APP_USER}/${APP_PWD}@${PROD_INSTANCE}
fi

printf "Updating UPG_STATUS table . . .\n"
echo "insert into UPG_STATUS values ('${PROD_INSTANCE}',sysdate,'${VERSION_NO}','${BUILD_NO}','${STATUS}','${RUN_MODE}','${NON_ACTIVE_REF}','${EXP_PATH}','${SCHEMAFILE}');
         exit; " | sqlplus -s ${APP_USER}/${APP_PWD}@${PROD_INSTANCE}
}

#-----------------------------
# Remove all Temporary Files
#-----------------------------
Remove_Tmp_Files()
{
\rm -f $LOGDIR/Tmp_*$$.*
\rm -f $WRKDIR/Tmp_*$$.*
\rm -f $DMPDIR/Tmp_*$$.*
}

#---------------------------
# Set Environment Variables
#---------------------------
Set_Env()
{
DAY=`date +%Y%m%d_%H%M%S` ; export DAY
if [ "`uname -s`" = "SunOS" ]
  then AWK=/usr/bin/nawk
       GREP=/usr/xpg4/bin/grep
       SED=/usr/xpg4/bin/sed
  elif [ "`uname -s`" = "Linux" ]
  then AWK=/bin/awk
       GREP=/bin/grep
       SED=/bin/sed
  else
       AWK=/usr/bin/awk
       GREP=/usr/bin/grep
       SED=/usr/bin/sed
fi
if [ -z "$ORACLE_HOME" ]
  then echo " ORACLE_HOME environment variable not found - please define it!"
       Exit_Func
fi
}

#-----------------
# Set Parameters
#-----------------
Set_Input()
{
export CURDIR=`pwd`
export RUNDIR=`dirname $0`
export WRKDIR=$CURDIR/Work; mkdir -p $WRKDIR
export DMPDIR=$CURDIR/Dmp;  mkdir -p $DMPDIR
export LOGDIR=$CURDIR/Log;  mkdir -p $LOGDIR ; touch $LOGDIR/trace_file.log
export LOGFILE=$LOGDIR/RefreshDatabase_$DAY_$$.log
export APP_USER=SA
export CONN=SACON
export SAREF1=SAREF1
export SAREF2=SAREF2
#VERSION_NO=`$GREP build.version $HOME/J2EEServer/config/CRM/VM/build.number | cut -d= -f2 | $SED 's#[a-z]##g'`
#export BUILD_NO=`$GREP build.number $HOME/J2EEServer/config/CRM/VM/build.number | cut -d= -f2`
# export WLPORT=`$GREP WL_PORT ${HOME}/J2EEServer/config/CRM/scripts/localSetEnv.ksh | cut -d= -f2`
export HOST=`hostname`
#export WLPORT=`$GREP WL_PORT= ${HOME}/J2EEServer/config/CRM/scripts/pingServer.sh | cut -d= -f2`
#export ENV_IP=`host $HOST | $GREP address | cut -d" " -f4`
}

#-----------------------------------
# Check Parameters from the ParFile
#-----------------------------------
Check_Parameters()
{
echo " Check validation of all parameters in the $PARFILE:" | tee -a $LOGFILE
echo " Checking Run Mode" | tee -a $LOGFILE
case $RUN_MODE in
    [1] ) echo " Handle refresh reference DB and CRM schema" | tee -a $LOGFILE;;
    [2] ) echo " Handle CRM schema only" | tee -a $LOGFILE;;
    [3] ) echo " Refresh reference schema only" | tee -a $LOGFILE;;
    [4] ) echo " Handle Release reference only" | tee -a $LOGFILE;;
    [5] ) echo " Handle Distribute reference only" | tee -a $LOGFILE;;
      * ) echo " Invalid run mode, please check the parameter file" | tee -a $LOGFILE; Exit_Func;;
esac

echo " Checking connections to all users" | tee -a $LOGFILE
Check_Connect $APP_USER  $APP_PWD       $PROD_INSTANCE
Check_Connect $CONN   $CONN_PWD   $PROD_INSTANCE
Check_Connect $SAREF1 $SAREF1_PWD $PROD_INSTANCE
Check_Connect $SAREF2 $SAREF2_PWD $PROD_INSTANCE

if [[ "$RUN_MODE" = "1" || "$RUN_MODE" = "3" || "$RUN_MODE" = "4" ]]
  then if [[ "$DEL_CONFIRM" != "Y" && "$DEL_CONFIRM" != "y" && "$DEL_CONFIRM" != "N" && "$DEL_CONFIRM" != "n" ]]
         then echo " Invalid answer to DEL_CONFIRM, you should enter Y/N only"
              Exit_Func
         elif [[ "$DEL_CONFIRM" = "Y" || "$DEL_CONFIRM" = "y" ]]
             then export DEL_CONFIRM=Y
                  if [[ "$EXP_CONFIRM" != "Y" && "$EXP_CONFIRM" != "y" && "$EXP_CONFIRM" != "N" && "$EXP_CONFIRM" != "n" ]]
                    then echo " Invalid answer to EXP_CONFIRM, you should enter Y/N only"
                         Exit_Func
                    elif [[ "$EXP_CONFIRM" = "Y" || "$EXP_CONFIRM" = "y" ]]
                         then export EXP_CONFIRM=Y
                              echo " Checking connection to the master reference" | tee -a $LOGFILE
                              Check_Connect $M_USERNAME $M_PASSWORD $M_INST
                              export EXP_FILE=${M_INST}_${DAY}_$$
                              export FROMUSER=$M_USERNAME
                    else export EXP_CONFIRM=N
			 export EXP_EXT=`echo $EXP_PATH | $AWK 'BEGIN {FS="."} {print $NF}'`
			 echo " Checking dmp file exist" | tee -a $LOGFILE
	        	 if [[ ! -f $EXP_PATH ]]
			   then echo " File $EXP_PATH Does Not Exist, you should give full path to the dmp file for EXP_PATH" | tee -a $LOGFILE
			   Exit_Func
                         elif [[ "$EXP_EXT" != "gz" && "$EXP_EXT" != "dmp" ]]
		             then echo " File $EXP_PATH is not a dmp file" | tee -a $LOGFILE
			     Exit_Func
			 else cp -f $EXP_PATH $DMPDIR/
			 export EXP_FILE=`echo $EXP_PATH |$AWK -F / '{print $NF}' | $AWK -F '\.dmp' '{print $1}'`
			 if [[ "$EXP_EXT" = "gz" ]]
			 then gunzip $DMPDIR/$EXP_FILE.dmp.gz
			 fi
                    fi
              fi
         else export DEL_CONFIRM=N
       fi
       if [[ "$DAT_CONFIRM1" != "Y" && "$DAT_CONFIRM1" != "y" && "$DAT_CONFIRM1" != "N" && "$DAT_CONFIRM1" != "n" ]]
         then echo " Invalid answer to DAT_CONFIRM1, you should enter Y/N only"
              Exit_Func
         elif [[ "$DAT_CONFIRM1" = "Y" || "$DAT_CONFIRM1" = "y" ]]
             then export DAT_CONFIRM1=Y
                  echo $DAT_PATH1 | $AWK -F ';' '{for (i=1;i<=NF;i++) print $i}' >> $LOGDIR/Dat_List_Ref_$$.lst
                  export DAT_LOCATION1=Dat_List_Ref_$$.lst
                  LST=`cat $LOGDIR/$DAT_LOCATION1`
                  for each in $LST
                  do
                      if [[ ! -f $each ]]
                        then echo " File $each Does Not Exist, you should give full path to the dat/sql file for DAT_PATH" | tee -a $LOGFILE
                             Exit_Func
                      fi
                      echo $each | $GREP -q "\.dat$"
                      if [ $? -ne 0 ]
                        then echo $each | $GREP -q "\.sql$"
                             if [ $? -ne 0 ]
                               then echo " File $each is not a dat file nor sql file" | tee -a $LOGFILE
                                    Exit_Func
                             fi
                      fi
                 done
         else export DAT_CONFIRM1=N
       fi

fi

if [[ "$RUN_MODE" = "1" || "$RUN_MODE" = "2" ]]
  then if [[ "$DAT_CONFIRM2" != "Y" && "$DAT_CONFIRM2" != "y" && "$DAT_CONFIRM2" != "N" && "$DAT_CONFIRM2" != "n" ]]
         then echo " Invalid answer to DAT_CONFIRM2, you should enter Y/N only"
              Exit_Func
         elif [[ "$DAT_CONFIRM2" = "Y" || "$DAT_CONFIRM2" = "y" ]]
             then export DAT_CONFIRM2=Y
                  echo $DAT_PATH2 | $AWK -F ';' '{for (i=1;i<=NF;i++) print $i}' >> $LOGDIR/Dat_List_App_$$.lst
                   export DAT_LOCATION2=Dat_List_App_$$.lst
                  LST=`cat $LOGDIR/$DAT_LOCATION2`
                  for each in $LST
                  do
                      if [[ ! -f $each ]]
                        then echo " File $each Does Not Exist, you should give full path to the dat/sql file for DAT_PATH" | tee -a $LOGFILE
                             Exit_Func
                      fi
                      echo $each | $GREP -q "\.dat$"
                      if [ $? -ne 0 ]
                        then echo $each | $GREP -q "\.sql$"
                             if [ $? -ne 0 ]
                               then echo " File $each is not a dat file nor sql file" | tee -a $LOGFILE
                                    Exit_Func
                             fi
                      fi
                  done
         else export DAT_CONFIRM2=N
       fi
       if [[ "$XML_CONFIRM" != "Y" && "$XML_CONFIRM" != "y" && "$XML_CONFIRM" != "N" && "$XML_CONFIRM" != "n" ]]
         then echo " Invalid answer to XML_CONFIRM, you should enter Y/N only"
              Exit_Func
         elif [[ "$XML_CONFIRM" = "Y" || "$XML_CONFIRM" = "y" ]]
             then export XML_CONFIRM=Y
         else export XML_CONFIRM=N
       fi
fi

if [[ "$RUN_MODE" = "5" ]]
  then if [[ "$RUN_CONFIRM" != "Y" && "$RUN_CONFIRM" != "y" && "$RUN_CONFIRM" != "N" && "$RUN_CONFIRM" != "n" ]]
         then echo " Invalid answer to RUN_CONFIRM, you should enter Y/N only"
              Exit_Func
         elif [[ "$RUN_CONFIRM" = "Y" || "$RUN_CONFIRM" = "y" ]]
             then export RUN_CONFIRM=Y
             else echo " Please run FullDatabse with RUN_MODE=4 First" | tee -a $LOGFILE
                  Exit_Func
       fi
fi

if [[ "$DAT_CONFIRM1" = "Y" || "$DAT_CONFIRM2" = "Y" ]]
  then if [[ ! -f $DATAEX_PATH ]]
         then echo " $DATAEX_PATH Does Not Exist, you should give full path to dataex" | tee -a $LOGFILE
              Exit_Func
       fi
fi
}

#------------------------------
# Check Connection to the DB
#------------------------------
Check_Connect()
{
USER=$1
PASSWORD=$2
INSTANCE=$3
CONN_STR=$USER/$PASSWORD@$INSTANCE
( sqlplus  ${CONN_STR} < /dev/null ) | $GREP "Connected to:" > /dev/null
if [ $? -ne 0 ]
  then echo " Failed to Connect to $USER in instance $INSTANCE" | tee -a $LOGFILE
       Exit_Func
  else echo " Connection to $USER is OK" | tee -a $LOGFILE
fi
}

#------------------------------
# Create the control table
#------------------------------
Cre_Crm_Ref_Info_Table()
{
t=`sqlplus -s $CONNSTR @crm_ref_info_cre.sql << EOF   > $LOGDIR/Tmp_crm_ref_info_cre_$$.log`
if [ `cat $LOGDIR/Tmp_crm_ref_info_cre_$$.log | $GREP "ORA-" | wc -l` -ne 0 ]
  then echo " Failed to Create control Table." | tee -a $LOGFILE
       Exit_Func
  else echo " Table CRM_REF_INFO Created successfully." | tee -a $LOGFILE
fi
}

#---------------------------------------
# Define Reference Users and Passwords
#---------------------------------------
Define_Ref_Users()
{
#The non active reference user is the most up-to-date user!
if [[ "$RUN_MODE" = "2" ]]
  #To maintain homogeneousness, we refer the non active reference as the active one in this mode.
  then export NON_ACTIVE_REF=`
       echo "set echo off head off verify off feed off pages 0 lin 100
               SELECT ACTIVE_REF_DB FROM CRM_REF_INFO;
               exit;
"| sqlplus -s $CONNSTR`
         export ACTIVE_REF=`
       echo "set echo off head off verify off feed off pages 0 lin 100
               select case when ACTIVE_REF_DB='SAREF1' then 'SAREF2' when ACTIVE_REF_DB='SAREF2' then 'SAREF1' end from CRM_REF_INFO
               exit;
"| sqlplus -s $CONNSTR`
else
#The non active reference user is the most up-to-date user!
export ACTIVE_REF=`
echo "set echo off head off verify off feed off pages 0 lin 100
        select ACTIVE_REF_DB FROM CRM_REF_INFO;
        exit;
"| sqlplus -s $CONNSTR`
export NON_ACTIVE_REF=`
echo "set echo off head off verify off feed off pages 0 lin 100
        select case when ACTIVE_REF_DB='SAREF1' then 'SAREF2' when ACTIVE_REF_DB='SAREF2' then 'SAREF1' end from CRM_REF_INFO
        exit;
"| sqlplus -s $CONNSTR`
fi
if [[ "$ACTIVE_REF" = "SAREF1" ]]
  then export ACTIVE_REF_PWD=$SAREF1_PWD
       export NON_ACTIVE_REF_PWD=$SAREF2_PWD
  else export ACTIVE_REF_PWD=$SAREF2_PWD
       export NON_ACTIVE_REF_PWD=$SAREF1_PWD
fi
}

#--------------------------------------------------
# Check Consistency Between the Ctl Table and Syn
#--------------------------------------------------
Check_Ctl_Syn()
{
ACTIVE=`
echo "set echo off head off verify off feed off pages 0 lin 120
SELECT distinct table_owner FROM user_synonyms;
exit;
"| sqlplus -s $CONNSTR`

if [[ "$RUN_MODE" = "2" ]]
  then if [ "$ACTIVE" != "$NON_ACTIVE_REF" ]
         then echo " There is Inconsistency Between the Ctl Table and Syn, Pls check " | tee -a $LogFile
              Exit_Func
         else echo " There is consistency Between the control Table and the reference's synonyms" | tee -a $LogFile
       fi
  else if [ "$ACTIVE" != "$ACTIVE_REF" ]
         then echo " There is Inconsistency Between the Ctl Table and Syn, Pls check " | tee -a $LogFile
              Exit_Func
         else echo " There is consistency Between the control Table and the reference's synonyms" | tee -a $LogFile
       fi
fi
}

#--------------------------------------
# Make Sure All Reference Tables Exist
#--------------------------------------
Check_Ref_Exist()
{
WORK_FILE=Check_RefTabs_Exist_$$.sql
LOG_FILE=Check_RefTabs_Exist_$$.log
LST=`cat $REFLIST`
for each in $LST
do
   echo "select count(*) from $each where rownum=1;" >> $WRKDIR/$WORK_FILE
done
t=`sqlplus -s $NON_ACTIVE_REF/$NON_ACTIVE_REF_PWD@$PROD_INSTANCE @$WRKDIR/$WORK_FILE << EOF > $LOGDIR/$LOG_FILE`
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -ne 0 ]
  then echo " Reference Tables Missing, check $LOGDIR/$LOG_FILE" | tee -a $LOGFILE
       Exit_Func
  else echo " All Reference Tables exist." | tee -a $LOGFILE
       mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
       mv $WRKDIR/$WORK_FILE $WRKDIR/Tmp_$WORK_FILE
fi
}

#---------------------
# Drop Users' Objects
#---------------------
DbDropAllObj()
{
USERNAME=$1
CONN_STR=$1/$2@$PROD_INSTANCE
echo " About to drop all objects of $USERNAME " | tee -a $LOGFILE
$RUNDIR/db_drop_all_obj -p $CONN_STR -o $LOGDIR
mv $CURDIR/db_drop_ALL_$USERNAME.sql $WRKDIR/Tmp_db_drop_ALL_$USERNAME_$$.sql
mv $LOGDIR/drop_ALL_$USERNAME.log $LOGDIR/drop_ALL_$USERNAME.log_${DAY}
if [ `cat $LOGDIR/drop_ALL_$USERNAME.log_${DAY} | $GREP "ORA-" | wc -l` -ne 0 ]
then
			echo " Errors while dropping $USERNAME objects, Check $LOGDIR/drop_ALL_$USERNAME.log_${DAY}" | tee -a $LOGFILE
      Exit_Func
else
			echo " All objects of $USERNAME user were dropped" | tee -a $LOGFILE
fi
}

#-------------------------------------------
# Export the data from the master reference
#-------------------------------------------
Do_Export()
{
M_CONN_STR=${M_USERNAME}/${M_PASSWORD}\@${M_INST}
${ORACLE_HOME}/bin/exp $M_CONN_STR file=$DMPDIR/$EXP_FILE.dmp log=$LOGDIR/$EXP_FILE.log statistics=none buffer=10485760
ORA_ERROR=`$GREP "ORA-" $LOGDIR/$EXP_FILE.log | $GREP "EXP-" $LOGDIR/$EXP_FILE.log | wc -l`
if [[ $ORA_ERROR -gt 0 ]]
  then echo " There are $ORA_ERROR errors in the Export process, Check $LOGDIR/$EXP_FILE.log" | tee -a $LOGFILE
       Exit_Func
  else echo " Export Master Reference Succeed"  | tee -a $LOGFILE
       mv $LOGDIR/$EXP_FILE.log $LOGDIR/Tmp_$EXP_FILE.log
fi
}

#-------------------------------------------
# Import the Data to the reference
#-------------------------------------------
Do_Import()
{
DbDropAllObj $NON_ACTIVE_REF $NON_ACTIVE_REF_PWD
touch ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/Do_Import_SUCCESS
if [[ "$REF_PARFILE" = "Y" ]]
then
	PARFILE_R=$CURDIR/ref_tables_list.par
	echo "tables=" > $PARFILE_R
	cat $RUNDIR/ref_tables_list.lst >> $PARFILE_R
	printf "\nTABLE_NUM_SCHEME" >> $PARFILE_R
	IMP_LOG_FILE=${EXP_FILE}_imp_$$.log
	${ORACLE_HOME}/bin/imp $NON_ACTIVE_REF/$NON_ACTIVE_REF_PWD@$PROD_INSTANCE file=$DMPDIR/$EXP_FILE.dmp log=$LOGDIR/$IMP_LOG_FILE fromuser=$FROMUSER touser=$NON_ACTIVE_REF buffer=10485760 parfile=$PARFILE_R
else
	IMP_LOG_FILE=${EXP_FILE}_imp_$$.log
	${ORACLE_HOME}/bin/imp $NON_ACTIVE_REF/$NON_ACTIVE_REF_PWD@$PROD_INSTANCE file=$DMPDIR/$EXP_FILE.dmp log=$LOGDIR/$IMP_LOG_FILE fromuser=$FROMUSER touser=$NON_ACTIVE_REF buffer=10485760
fi
ORA_ERROR=`$GREP "ORA-" $LOGDIR/$IMP_LOG_FILE | $GREP "IMP-" $LOGDIR/$IMP_LOG_FILE | $GREP -v IMP-00041 | wc -l`
if [[ $ORA_ERROR -gt 0 ]]
then
	echo " There are $ORA_ERROR errors in the Import process, Check $LOGDIR/$IMP_LOG_FILE" | tee -a $LOGFILE
	\rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/Do_Import_SUCCESS
##  Exit_Func
else
	echo " Import Master Reference Succeed"  | tee -a $LOGFILE
#  mv $LOGDIR/$IMP_LOG_FILE $LOGDIR/Tmp_$IMP_LOG_FILE
fi
}

#-----------------
# Run Dat files
#-----------------
Run_Dataex()
{
USERNAME=$1
PASSWORD=$2
FILE_NAME=$3
LOG_FILE=$4
echo "dataex command: $DATAEX_PATH -user_name $USERNAME -password XXXX -db_name clarify -db_server $PROD_INSTANCE -imp $FILE_NAME -log_file $LOGDIR/$LOG_FILE -db_driver oracle " >> $LOGFILE
$DATAEX_PATH -user_name $USERNAME -password $PASSWORD -db_name clarify -db_server $PROD_INSTANCE -imp $FILE_NAME -log_file $LOGDIR/$LOG_FILE -db_driver oracle >> $LOGDIR/dataex_1_$$.log
mv $CURDIR/server.log $LOGDIR/server.log
mv $CURDIR/dataex.mes $LOGDIR/dataex.mes
if [[ -f $LOGDIR/dataex.mes && ! -s $LOGDIR/dataex.mes ]]
  then echo " Dat file $FILE_NAME executed successfully" | tee -a $LOGFILE
       mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
       mv $LOGDIR/server.log $LOGDIR/Tmp_server.log
       mv $LOGDIR/dataex.mes $LOGDIR/Tmp_dataex.mes
       mv $LOGDIR/dataex_1_$$.log $LOGDIR/Tmp_dataex_1_$$.log
  else echo " Failed to run dat file $each, Check $LOG_FILE, dataex_1_$$.log, dataex.mes, server.log under $LOGDIR/" | tee -a $LOGFILE
       Exit_Func
fi
}

#-----------------
# Run Sql files
#-----------------
Run_Sqlplus()
{
USERNAME=$1
PASSWORD=$2
FILE_NAME=$3
LOG_FILE=$4
t=`sqlplus -s $USERNAME/$PASSWORD@$PROD_INSTANCE @$FILE_NAME << EOF   > $LOGDIR/$LOG_FILE`
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -eq 0 ]
  then echo " Sql file $FILE_NAME executed successfully" | tee -a $LOGFILE
       mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
  else echo " Failed to run sql file $FILE_NAME, Check $LOGDIR/$LOG_FILE" | tee -a $LOGFILE
       Exit_Func
fi
}

#------------------------
# Handle the UPD tables
#------------------------
Handle_UPD()
{
LOG_FILE=3_create_UDP_tables_$$.log
t=`sqlplus -s $CONNSTR @3_create_UDP_tables.sql << EOF   > $LOGDIR/$LOG_FILE`
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | $GREP -v "ORA-02289" | wc -l` -ne 0 ]
  then echo " There are errors in UPD tables for $NON_ACTIVE_REF, check $LOGDIR/$LOG_FILE" | tee -a $LOGFILE
       Exit_Func
  else echo " UPD Tables Handled successfully" | tee -a $LOGFILE
       mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
fi
}

#---------------------------
# Update table_config_itm
#---------------------------
Upd_Config_Itm()
{
CONN_STR=$1

TABLE_EXIST_TABLE_CONFIG_ITM=`
      echo " set echo off head off verify off feed off pages 0 lin 100
	    select TABLE_NAME from TABS where TABLE_NAME='TABLE_CONFIG_ITM';
	    grant select on TABLE_CONFIG_ITM to $NON_ACTIVE_REF;
	    exit;
	   "| sqlplus -s $ACTIVE_REF/$ACTIVE_REF_PWD@$PROD_INSTANCE`
if [[ "$TABLE_EXIST_TABLE_CONFIG_ITM" = "TABLE_CONFIG_ITM" ]]
then
	SOURCE_DB=$ACTIVE_REF
else
	SOURCE_DB=$APP_USER
fi
CONFIG_ITM_LOG_FILE=${DAY}_Config_Itm_Handl.log
sqlplus -s $CONN_STR <<!
spool $LOGDIR/$CONFIG_ITM_LOG_FILE
show user
set echo on
select global_name from global_name;

create table TABLE_CONFIG_ITM_B4_REFRESH as select * from $SOURCE_DB.TABLE_CONFIG_ITM;
create table TABLE_CONFIG_ITM_IMPORTED as
select *
from   TABLE_CONFIG_ITM;

delete TABLE_CONFIG_ITM;

insert into TABLE_CONFIG_ITM
select *
from   TABLE_CONFIG_ITM_B4_REFRESH
where  name in ( 'UAMS_ENV_KEY',
                 'routing_server_ip',
                 'routing_server_port',
                 'autodest_servlet_ip',
                 'autodest_servlet_port',
                 'UAMS_APP_ID',
                 'UAMS_NAMESPACE',
                 'FormPostedAtLogin')
or     name like 'time stamp of%';

delete TABLE_CONFIG_ITM
where  OBJID in ( select tcii.OBJID
                  from   TABLE_CONFIG_ITM_IMPORTED tcii,
                         TABLE_CONFIG_ITM tci
                  where  tcii.name <> tci.name
                  and    tcii.OBJID=tci.OBJID);
                  insert into table_config_itm ( select *
                               from   TABLE_CONFIG_ITM_IMPORTED
                               where  name not in ( 'UAMS_ENV_KEY',
                                                    'routing_server_ip',
                                                    'routing_server_port',
                                                    'autodest_servlet_ip',
                                                    'autodest_servlet_port',
                                                    'UAMS_APP_ID',
                                                    'UAMS_NAMESPACE',
                                                    'FormPostedAtLogin')
                               and    name not like 'time stamp of%');

insert into table_config_itm ( select *
                               from   TABLE_CONFIG_ITM_IMPORTED
                               where  ( name in ( 'UAMS_ENV_KEY',
                                                'routing_server_ip',
                                                'routing_server_port',
                                                'autodest_servlet_ip',
                                                'autodest_servlet_port',
                                                'UAMS_APP_ID',
                                                'UAMS_NAMESPACE',
                                                'FormPostedAtLogin')
                                       or name like 'time stamp of%')
                               and    name not in ( select name
                                                    from   TABLE_CONFIG_ITM));

drop table TABLE_CONFIG_ITM_B4_REFRESH;
drop table TABLE_CONFIG_ITM_IMPORTED;
spool off
exit;
!


  if [ `cat $LOGDIR/$CONFIG_ITM_LOG_FILE | ${GREP} "ORA-" | wc -l` -gt 0 ]
  then echo " There are problems in the update table_config_itm , check $LOGDIR/$CONFIG_ITM_LOG_FILE" | tee -a $LOGFILE
      # Exit_Func
  else echo " table_config_itm successfully Updated." | tee -a $LOGFILE
       mv $LOGDIR/$CONFIG_ITM_LOG_FILE $LOGDIR/Tmp_$CONFIG_ITM_LOG_FILE
fi
}

#---------------------------
# Handle Table_Num_Scheme
#---------------------------
Upd_Num_Scheme()
{
sqlplus -s $NON_ACTIVE_REF/$NON_ACTIVE_REF_PWD@$PROD_INSTANCE << END_AIF
spool ${LOGDIR}/${DAY}_Aif_Operation.log
show user
GRANT ALTER, DELETE, INSERT, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON AIF_OPERATION TO CLARIFY_ADMINISTRATOR;
GRANT SELECT ON AIF_OPERATION TO CLARIFY_REPORTER;
GRANT DELETE, INSERT, SELECT, UPDATE ON AIF_OPERATION TO CLARIFY_USER;
spool off
exit;
END_AIF

sqlplus -s $CONNSTR << END_NUM_SCHEME
spool ${LOGDIR}/${DAY}_Num_Scheme.log
show user
create table table_num_scheme_old as select * from table_num_scheme;
truncate table table_num_scheme;
insert into TABLE_NUM_SCHEME (select * from $NON_ACTIVE_REF.TABLE_NUM_SCHEME);
set serveroutput on size 1000000

DECLARE
  num_read_recs NUMBER := 0;
  num_upd_recs NUMBER := 0;
BEGIN

  FOR tnso_cursor IN ( SELECT NAME,
                              NEXT_VALUE
                       FROM   table_num_scheme_old
                       WHERE  name in (select name
                                       from   table_num_scheme))
  LOOP

    num_read_recs := num_read_recs + 1;

    BEGIN

      UPDATE table_num_scheme
      SET    next_value = tnso_cursor.NEXT_VALUE
      WHERE  NAME = tnso_cursor.NAME;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN

      num_upd_recs := num_upd_recs - 1;

    WHEN OTHERS THEN

      DBMS_OUTPUT.PUT_LINE('ERROR when update table_num_scheme');
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
      EXIT;

    END;

    num_upd_recs := num_upd_recs + 1;

  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Number of selected records from table_num_scheme_old: ' || num_read_recs);
  DBMS_OUTPUT.PUT_LINE('Number of updated records in table_num_scheme: ' || num_upd_recs);

END;
/
update table_num_scheme
set    next_value = start_value
where  objid in ( select tnsn.objid
                  from   table_num_scheme tnsn,
                         table_num_scheme_old tnso
                  where  tnsn.name = tnso.name
                  and    tnsn.start_value > tnso.next_value);

commit;

drop table table_num_scheme_old;
spool off

quit;
END_NUM_SCHEME

}

#-------------------------------------
# Give Grants on all reference tables
#-------------------------------------
Create_Grants()
{
CONN_STR=$1
GRANTEE=$2
LOG_FILE=Script_grants_for_REF_$$.log
t=`sqlplus -s $CONN_STR @create_ref_grants.sql $GRANTEE << EOF   > $LOGDIR/$LOG_FILE`
mv Script_grants_for_REF.sql $WRKDIR/Script_grants_for_REF_$$.sql
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -ne 0 ]
  then echo " There are Some Errors in the Grants, check $LOGDIR/$LOG_FILE and Fix it." | tee -a $LOGFILE
       Exit_Func
  else echo " grants given to $GRANTEE." | tee -a $LOGFILE
       mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
       mv $WRKDIR/Script_grants_for_REF_$$.sql $WRKDIR/Tmp_Script_grants_for_REF_$$.sql
fi
}

#-----------------------------------------------------
# Revoke Unnecessary Grants from all reference tables
#-----------------------------------------------------
Revoke_Unnecessary_Grants()
{
CONN_STR=$1
OWNER=$2
ROLE=CLARIFY_USER
WORK_FILE=Script_revoke_from_REF_$$.sql
LOG_FILE=Script_revoke_from_REF_$$.log
echo "set lines 200 pages 0 trims on feedback off verify off head off"  >> $WRKDIR/$WORK_FILE
echo "spool Script_revoke_from_REF_${DAY}.sql"                                 >> $WRKDIR/$WORK_FILE
LST=`cat $REFLIST`
for each in $LST
do
   echo "select 'revoke '||PRIVILEGE||' on '||TABLE_NAME||' from '||GRANTEE||';' from USER_TAB_PRIVS"   >> $WRKDIR/$WORK_FILE
   echo "where OWNER='$OWNER' and GRANTEE='$ROLE' and TABLE_NAME='$each' and PRIVILEGE!='SELECT'"       >> $WRKDIR/$WORK_FILE
   echo "minus"                                                                                         >> $WRKDIR/$WORK_FILE
   echo "select 'revoke '||PRIVILEGE||' on '||TABLE_NAME||' from '||GRANTEE||';' from USER_TAB_PRIVS"   >> $WRKDIR/$WORK_FILE
   echo "where OWNER='$OWNER' and GRANTEE='$ROLE' and TABLE_NAME in ('TABLE_CONFIG_ITM','TABLE_QUEUE')" >> $WRKDIR/$WORK_FILE
   echo "and PRIVILEGE='UPDATE'"                                                                       >> $WRKDIR/$WORK_FILE
   echo "minus"                                                                                         >> $WRKDIR/$WORK_FILE
   echo "select 'revoke '||PRIVILEGE||' on '||TABLE_NAME||' from '||GRANTEE||';' from USER_TAB_PRIVS"   >> $WRKDIR/$WORK_FILE
   echo "where OWNER='$OWNER' and GRANTEE='$ROLE' and TABLE_NAME in ('TABLE_NUM_SCHEME')"               >> $WRKDIR/$WORK_FILE
   echo "and PRIVILEGE in ('UPDATE','INSERT');"                                                         >> $WRKDIR/$WORK_FILE
done
echo "spool off;"                                                       >> $WRKDIR/$WORK_FILE
echo "set echo on"                                                      >> $WRKDIR/$WORK_FILE
echo "@Script_revoke_from_REF_${DAY}.sql"                               >> $WRKDIR/$WORK_FILE
echo "exit;"                                                            >> $WRKDIR/$WORK_FILE
t=`sqlplus $CONN_STR @$WRKDIR/$WORK_FILE << EOF > $LOGDIR/$LOG_FILE`
mv Script_revoke_from_REF_${DAY}.sql $WRKDIR/Script_revoke_from_REF_${DAY}.sql
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | $GREP -v ORA-01927 | wc -l` -ne 0 ]
  then echo " There are Some Errors in the revoke process, check $LOGDIR/$LOG_FILE and Fix it." | tee -a $LOGFILE
       Exit_Func
  else echo " Revoke unnecessary grants finished successfully" | tee -a $LOGFILE
       mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
       mv $WRKDIR/$WORK_FILE $WRKDIR/Tmp_$WORK_FILE
     #  mv $WRKDIR/Script_revoke_from_REF.sql $WRKDIR/Tmp_Script_revoke_from_REF_$$.sql
fi
}

#--------------------------------------
# Rename Reference tables in App User
#--------------------------------------
RenameTabs()
{
LST=`cat $REFLIST`
WORK_FILE=Rename_Tabs_Ref_$$.sql
LOG_FILE=Rename_Tabs_Ref_$$.log
touch ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/RenameTabs_SUCCESS
echo "sho user " > $WRKDIR/$WORK_FILE
for each in $LST
do
    TPRFX=`echo $each | cut -d'_' -f1`
    TPSFX=`echo $each | cut -d'_' -f2-`
    case ${TPRFX} in
    TABLE) echo "Rename $each to \"ZT_${TPSFX}\";" >> $WRKDIR/$WORK_FILE ;;
    MTM)echo "Rename $each to \"ZM_${TPSFX}\";" >> $WRKDIR/$WORK_FILE ;;
    *)echo "Rename $each to \"Z${each}\";" >> $WRKDIR/$WORK_FILE ;;
    esac
done

echo "exit" >> $WRKDIR/$WORK_FILE

t=`sqlplus -s $CONNSTR @$WRKDIR/$WORK_FILE << EOF   > $LOGDIR/$LOG_FILE`
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | $GREP -v ORA-00955 | $GREP -v ORA-04043 | wc -l` -ne 0 ]
then
				echo " Error In Renaming Reference Tables in $APP_USER, Check $LOGDIR/$LOG_FILE"  | tee -a $LOGFILE
				\rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/RenameTabs_SUCCESS
        Exit_Func
else
				echo " Rename reference tables in $APP_USER succeed."  | tee -a $LOGFILE
        mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
        mv $WRKDIR/$WORK_FILE $WRKDIR/Tmp_$WORK_FILE
fi
}

#------------------------------
# Drop Synonyms to Reference
#------------------------------
DropSyn()
{
LST=`cat $REFLIST`
WORK_FILE=Drop_Syn_Ref_$$.sql
LOG_FILE=Drop_Syn_Ref_$$.log
touch ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/DropSyn_SUCCESS

sqlplus -s $CONNSTR << EOF
set echo off head off verify off feed off pages 0 lin 100
spool ${WRKDIR}/${WORK_FILE}
select 'drop synonym '||synonym_name||';' from syn where table_owner like '%REF%';
spool off
set echo on head on verify on feed on
spool ${LOGDIR}/${LOG_FILE}
@${WRKDIR}/${WORK_FILE}
spool off
EOF

if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | $GREP -v ORA-01434 | wc -l` -ne 0 ]
then
				echo " Error In Dropping Reference Synonyms, Check $LOGDIR/$LOG_FILE"  | tee -a $LOGFILE
				\rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/DropSyn_SUCCESS
        Exit_Func
else
				echo " Drop Reference Synonyms Succeed."  | tee -a $LOGFILE
#        mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
#        mv $WRKDIR/$WORK_FILE $WRKDIR/Tmp_$WORK_FILE
fi
}

#-------------------------------------------
# Return the reference tables in SA account
#-------------------------------------------
ReturnRefTabs()
{
LST=`cat $REFLIST`
for each in $LST
do
    TPRFX=`echo $each | cut -d'_' -f1`
    TPSFX=`echo $each | cut -d'_' -f2-`

    case ${TPRFX} in
    TABLE) SNAME="ZT_${TPSFX}" ;;
    MTM) SNAME="ZM_${TPSFX}" ;;
    *)SNAME="Z${each}" ;;
    esac

    IS_TABLE_EXIST=`
    echo "set echo off head off verify off feed off pages 0 lin 100
    select count(*) FROM user_tables where table_name = '$each';
    exit;
"| sqlplus -s $CONNSTR`

    if [[ `echo ${IS_TABLE_EXIST}| $AWK '{FS=" "; print $1}'` = 0 ]];       # If =1 - table exist and nothing should be done
      then IS__TABLE_EXIST=`
           echo "set echo off head off verify off feed off pages 0 lin 100
           select count(*) FROM user_tables where table_name = '${SNAME}';
           exit;
"| sqlplus -s $CONNSTR`
           if [[ `echo ${IS__TABLE_EXIST}| $AWK '{FS=" "; print $1}'` = 1 ]];   # If =1 - needs to rename back
             then sqlplus -s $CONNSTR << END_RENAME_TABLE
                  rename "${SNAME}" to $each;
                  exit;
END_RENAME_TABLE
             else #itsik
             echo " Warning - Table $each doesn't exist on the app user: $APP_USER "  | tee -a $LOGFILE
             #		 If =0 - needs to create from active ref
             #     sqlplus -s $CONNSTR << END_CREATE_TABLE
             #     create table $each as select * from $ACTIVE_REF.$each;
             #     exit;
	     #END_CREATE_TABLE
             #     WORK_FILE=create_Ref_$each_${DAY}.sql
             #     LOG_FILE=create_Ref_$each_${DAY}.log
             #     echo "set longc 90000 heading off pages 0 long 90000 lines 2000" >> $WRKDIR/$WORK_FILE
             #     echo "execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);" >> $WRKDIR/$WORK_FILE
             #     echo "execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);" >> $WRKDIR/$WORK_FILE
             #     echo "spool $WRKDIR/create_index_$each_${DAY}.sql" >> $WRKDIR/$WORK_FILE
             #     echo "SELECT DBMS_METADATA.GET_DDL('INDEX',index_name)FROM user_indexes where table_name='$each' and INDEX_TYPE='NORMAL';" >> $WRKDIR/$WORK_FILE
             #     echo "spool off" >> $WRKDIR/$WORK_FILE
             #     t=`sqlplus -s $ACTIVE_REF/$ACTIVE_REF_PWD@$PROD_INSTANCE @$WRKDIR/$WORK_FILE << EOF   > $LOGDIR/$LOG_FILE`
             #     if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -ne 0 ]
             #                         then echo " Problem in generating script to create table and indexes for $each, check $LOGDIR/$LOG_FILE"  | tee -a $LOGFILE
             #            Exit_Func
             #       else cat $WRKDIR/create_index_$each_${DAY}.sql |$SED "s/\"$ACTIVE_REF\"/\"SA\"/g" | $RUNDIR/Clean.pl > $WRKDIR/create_index1_$each_${DAY}.sql
             #            mv $WRKDIR/$WORK_FILE $WRKDIR/Tmp_$WORK_FILE_$$
             #            mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE_$$
             #            mv $WRKDIR/create_index_$each_${DAY}.sql $WRKDIR/Tmp_create_index_$each.sql_$$
             #     fi
             #     LOG_FILE=create_index1_$each.log
             #     t=`sqlplus -s $CONNSTR @$WRKDIR/create_index1_$each_${DAY}.sql << EOF   > $LOGDIR/$LOG_FILE`
             #     if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -ne 0 ]
             #       then echo " Problem in creating indexes for $each, check $LOGDIR/$LOG_FILE"  | tee -a $LOGFILE
             #            Exit_Func
             #       else echo mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE_$$
             #                     t=`sqlplus -s $CONNSTR @$WRKDIR/create_index1_$each_${DAY}.sql << EOF   > $LOGDIR/$LOG_FILE`
             #     fi
           fi
    fi
done

ZTABS=`
    echo "set echo off head off verify off feed off pages 0 lin 100
    select count(*) FROM user_tables where table_name like 'Z%';
    exit;
"| sqlplus -s $CONNSTR`

if [ ${ZTABS} -ne 0 ]
then
	Check_Rename_Tabs
fi

echo " Create/Return Reference Tables in $APP_USER Account Succeed."  | tee -a $LOGFILE
}

#---------------------------------" >> $LOGFILE
# Handle New Objects - x_dbtune   " >> $LOGFILE
#---------------------------------" >> $LOGFILE
RunXDbtune()
{
LOG_FILE=run_x_dbtune_$$.log
t=`sqlplus -s $CONNSTR @${CLARIFY_DIR}/x_dbtune.sql << EOF   > $LOGDIR/$LOG_FILE`
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | $GREP -v ORA-00955 | $GREP -v ORA-01408 | wc -l` -ne 0 ]
then
		echo " Errors in adding new objects, Check $LOGDIR/$LOG_FILE"  | tee -a $LOGFILE
else
		echo " x_dbtune script run successfully."  | tee -a $LOGFILE
#    mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
fi
}

#---------------------------------
# Delete Views before running xml - added by itsik
#---------------------------------
Delete_Views()
{
echo " Deleting Views" | tee -a $LOGFILE
$CURDIR/prep_delete_sql_view.sh $APP_USER $APP_PWD $PROD_INSTANCE
mv $CURDIR/tab_name_id.lst $LOGDIR/Tmp_name_id_$$.lst
mv delete_sql_view.sql $WRKDIR/delete_sql_view_$$.sql
LOG_FILE=delete_sql_view_$$.log
t=`sqlplus -s $CONNSTR @$WRKDIR/delete_sql_view_$$.sql << EOF   > $LOGDIR/$LOG_FILE`
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -ne 0 ]
  then
	 echo " There were errors while deleting views, please check $LOGDIR/$LOG_FILE.log "
	 \rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/Run_XML_Schema_SUCCESS
	 Exit_Func
  else echo " Views Successfully Deleted " | tee -a $LOGFILE
  	mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
  	mv $WRKDIR/delete_sql_view_$$.sql $WRKDIR/Tmp_delete_sql_view_$$.sql
fi
}

#--------------------------------
# Create Synonyms to Reference
#--------------------------------
CreateSyn()
{
LST=`cat $REFLIST`
WORK_FILE=Create_Syn_Back_$$.sql
LOG_FILE=Create_Syn_Back_$$.log
touch ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/CreateSyn_SUCCESS
echo "sho user " >> $WRKDIR/$WORK_FILE
for each in $LST
do
    echo "CREATE OR REPLACE SYNONYM $each FOR $NON_ACTIVE_REF.$each;" >> $WRKDIR/$WORK_FILE
done
echo "exit" >> $WRKDIR/$WORK_FILE

t=`sqlplus -s $CONNSTR @$WRKDIR/$WORK_FILE << EOF   > $LOGDIR/$LOG_FILE`
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -ne 0 ]
then
				echo " Error in creating synonyms to reference account , Check $LOGDIR/$LOG_FILE"  | tee -a $LOGFILE
				\rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/CreateSyn_SUCCESS
        Exit_Func
else
				echo " Create synonyms to reference account succeed."  | tee -a $LOGFILE
        mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
        mv $WRKDIR/$WORK_FILE $WRKDIR/Tmp_$WORK_FILE
fi
}

#-----------------------
# Drop Public Synonyms
#-----------------------
Drop_Pub_Syn()
{
USERNAME=$1
PASSWORD=$2
LOG_FILE=Drop_Pub_Syn_$$.log
t=`sqlplus -s $USERNAME/$PASSWORD@$PROD_INSTANCE @drop_public_syn.sql $USERNAME $WRKDIR/Drop_Pub_Syn_${DAY}.sql << EOF   > $LOGDIR/$LOG_FILE`
mv $WRKDIR/Drop_Pub_Syn_${DAY}.sql $WRKDIR/Drop_Pub_Syn_$$.sql
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -ne 0 ]
  then
	echo " Error In Dropping Public Synonyms from $USERNAME Account , Check $LOG_FILE"  | tee -a $LOGFILE
        Exit_Func
  else
	echo " Drop Public Synonyms from $USERNAME Account Succeed."  | tee -a $LOGFILE
        mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
        mv $WRKDIR/Drop_Pub_Syn_$$.sql $WRKDIR/Tmp_Drop_Pub_Syn_$$.sql
fi
}

#---------------------------
# revoke grants from public
#---------------------------
Rvk_Grants_Pub()
{
USERNAME=$1
PASSWORD=$2
LOG_FILE=revoke_public_grants_$$.log
t=`sqlplus -s $USERNAME/$PASSWORD@$PROD_INSTANCE @revoke_priv_from_public.sql $WRKDIR/Revoke_priv_from_public_${DAY}.sql << EOF   > $LOGDIR/$LOG_FILE`
mv $WRKDIR/Revoke_priv_from_public_${DAY}.sql $WRKDIR/Revoke_priv_from_public_$$.sql
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | $GREP -v "ORA-01927" | wc -l` -ne 0 ]
  then echo " Problem in revokeing public grants in $USERNAME, check $LOGDIR/$LOG_FILE" | tee -a $LOGFILE
       Exit_Func
  else echo " Revoking public grant from $USERNAME finished successfully." | tee -a $LOGFILE
       mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
       mv $WRKDIR/Revoke_priv_from_public_$$.sql $WRKDIR/Tmp_Revoke_priv_from_public_$$.sql
fi
}

#-----------------------------------
# Prepare Scripts for the Synonyms
#-----------------------------------
PrepareSyn()
{
LOG_FILE=create_script_syn_tab_$$.log
t=`sqlplus -s $CONNSTR @create_script_syn_tab.sql $WRKDIR/Script_Create_Syn_For_SA_${DAY}.sql << EOF   > $LOGDIR/$LOG_FILE`
mv $WRKDIR/Script_Create_Syn_For_SA_${DAY}.sql $WRKDIR/Script_Create_Syn_For_SA_$$.sql
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -ne 0 ]
  then echo " Failed to Create script for synonyms, check $LOGDIR/$LOG_FILE" | tee -a $LOGFILE
       Exit_Func
  else echo " Script_Create_Syn_For_SA_${DAY}.sql Created." | tee -a $LOGFILE
       mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
fi
LOG_FILE=create_script_syn_views_$$.log
t=`sqlplus -s $CONNSTR @create_script_syn_views.sql $WRKDIR/Script_Create_Syn_For_Views_SA_${DAY}.sql << EOF   > $LOGDIR/$LOG_FILE`
mv $WRKDIR/Script_Create_Syn_For_Views_SA_${DAY}.sql $WRKDIR/Script_Create_Syn_For_Views_SA_$$.sql
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -ne 0 ]
  then echo " Failed to Create script for synonyms, check $LOGDIR/$LOG_FILE" | tee -a $LOGFILE
       Exit_Func
  else echo " Script_Create_Syn_For_Views_SA_${DAY}.sql Created." | tee -a $LOGFILE
       mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
fi
}

#------------------------------------
# Create sacon synonyms
#------------------------------------
RunSyn()
{
t=`sqlplus -s $CONN/$CONN_PWD@$PROD_INSTANCE @$WRKDIR/Script_Create_Syn_For_SA_$$.sql << EOF   > $LOGDIR/Script_Create_Syn_For_SACON_$$.log`
if [ `cat $LOGDIR/Script_Create_Syn_For_SACON_$$.log | $GREP "ORA-" | wc -l` -ne 0 ]
  then echo " Failed to create synonyms to $CONN, check $LOGDIR/Script_Create_Syn_For_SACON_$$.log" | tee -a $LOGFILE
       Exit_Func
  else echo " Synonyms for all objects beside views successfully created on $CONN." | tee -a $LOGFILE
       mv $LOGDIR/Script_Create_Syn_For_SACON_$$.log $LOGDIR/Tmp_Script_Create_Syn_For_SACON_$$.log
fi
t=`sqlplus -s $CONN/$CONN_PWD@$PROD_INSTANCE @$WRKDIR/Script_Create_Syn_For_Views_SA_$$.sql << EOF   > $LOGDIR/Script_Create_Syn_For_Views_SA_$$.log`
if [ `cat $LOGDIR/Script_Create_Syn_For_Views_SA_$$.log | $GREP "ORA-" | wc -l` -ne 0 ]
  then echo " Failed to create synonyms for views to $CONN, check $LOGDIR/Script_Create_Syn_For_Views_SA_$$.log" | tee -a $LOGFILE
       Exit_Func
  else echo " Synonyms for all views successfully created on $CONN." | tee -a $LOGFILE
       mv $LOGDIR/Script_Create_Syn_For_Views_SA_$$.log $LOGDIR/Tmp_Script_Create_Syn_For_Views_SA_$$.log
fi
mv $WRKDIR/Script_Create_Syn_For_SA_$$.sql $WRKDIR/Tmp_Script_Create_Syn_For_SA_$$.sql
mv $WRKDIR/Script_Create_Syn_For_Views_SA_$$.sql $WRKDIR/Tmp_Script_Create_Syn_For_Views_SA_$$.sql
}

#-----------------------------
# Compile all views in the DB
#-----------------------------
Compile_Views()
{
USERNAME=$1
PASSWORD=$2
LOG_FILE=Compile_Views_$USERNAME_$$.log
t=`sqlplus -s $USERNAME/$PASSWORD@$PROD_INSTANCE @compile_views.sql $WRKDIR/Compile_Views_${DAY}.sql << EOF   > $LOGDIR/$LOG_FILE`
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | $GREP "Warning"| wc -l` -ne 0 ]
  then echo " There are Errors while compiling the views for $USERNAME, check $LOGDIR/$LOG_FILE" | tee -a $LOGFILE
       Exit_Func
  else echo " Views Compile Successfully for $USERNAME." | tee -a $LOGFILE
       mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
       mv $WRKDIR/Compile_Views_${DAY}.sql $WRKDIR/Tmp_Compile_Views_$$.sql
fi
}

#------------------------------------
# Compile all other invalid objects
#------------------------------------
CompileObj()
{
USERNAME=$1
PASSWORD=$2
echo "exec dbms_utility.compile_schema('$USERNAME');
      exit; " | sqlplus -s $USERNAME/$PASSWORD@$PROD_INSTANCE
}

#---------------------------------------------------
# Grant Core sequences MESSAGE_SEQ and BG_ACTION_SEQ
#---------------------------------------------------
GrantSeq()
{
USERNAME=$1
PASSWORD=$2
sqlplus -s $USERNAME/$PASSWORD@$PROD_INSTANCE << END_GRANT_SEQ
grant select on MESSAGE_SEQ to CLARIFY_USER;
grant select on BG_ACTION_SEQ to CLARIFY_USER;
grant select on MESSAGE_SEQ to CLARIFY_REPORTER;
grant select on BG_ACTION_SEQ to CLARIFY_REPORTER;
exit;
END_GRANT_SEQ
}


#----------------
# Run Statistics
#----------------
Run_Stat()
{
LOG_FILE=Run_Stat_$$.log
WORK_FILE=Run_Stat_$$.sql
OWNNAME=$1
CONN_STR=$2
PCT=5
for each in $LST
do
	echo "set echo on" >> $WRKDIR/$WORK_FILE
	echo "exec dbms_stats.GATHER_TABLE_STATS(OWNNAME=>'$OWNNAME',TABNAME=>'$each',ESTIMATE_PERCENT =>$PCT,BLOCK_SAMPLE => TRUE,METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE 1',DEGREE => 12,GRANULARITY=>'ALL',CASCADE=>TRUE);" >> $WRKDIR/$WORK_FILE
done

echo "exit" >> $WRKDIR/$WORK_FILE

t=`sqlplus -s $CONN_STR @$WRKDIR/$WORK_FILE << EOF   > $LOGDIR/$LOG_FILE`
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | $GREP -v ORA-20000 | $GREP -v ORA-06512 |wc -l` -ne 0 ]
then
	echo "Error while gathering statistics for $OWNNAME, Check $LOGDIR/$LOG_FILE"  | tee -a $LOGFILE
else
	echo "Gathering statistics for $OWNNAME Succeed."  | tee -a $LOGFILE
	mv $LOGDIR/$LOG_FILE $LOGDIR/Tmp_$LOG_FILE
	mv $WRKDIR/$WORK_FILE $WRKDIR/Tmp_$WORK_FILE
fi
}

#----------------------------
# Update CRM_REF_INFO table
#----------------------------
Upd_Crm_Ref_Info_Table()
{
echo "update CRM_REF_INFO set ACTIVE_REF_DB='$NON_ACTIVE_REF', LAST_RUN_DATE=SYSDATE;
      exit; " | sqlplus -s $CONNSTR
}

#-------------------------------------
# Check if Script will run on Fix Mode
#-------------------------------------
Check_Fix_Mode()
{
if test -d ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS
then
	FIX_MODE=Y
	echo "Script Will Run On Fix Mode" | tee -a $LOGFILE
else
	FIX_MODE=N
	mkdir -p ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS
	echo "Script Will Run On Regular Mode" | tee -a $LOGFILE
fi
}

#-------------------------------------
# Check if function was run or not
#-------------------------------------
Check_If_Done ()
{
if [ -f "${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/${1}_SUCCESS" ]
then
	return 0
else
	return 1
fi
}

#------------------------------------------
# Create table all_indexes where owner='SA'
#------------------------------------------
Cre_Tab_All_Indexes()
{
LOG_FILE=Tmp_Create_TAB_all_indexes_$$.log
sqlplus -s ${APP_USER}/${APP_PWD}@${PROD_INSTANCE}  << EOF   > $LOGDIR/$LOG_FILE
	create or replace view ALL_INDEXES as (select * from SYS.ALL_INDEXES where owner='SA');
	exit;
EOF
}

#----------------------------------------
# Drop table all_indexes where owner='SA'
#----------------------------------------
Drop_Tab_All_Indexes()
{
LOG_FILE=Tmp_Drop_Tab_All_Indexes_$$.log
sqlplus -s ${APP_USER}/${APP_PWD}@${PROD_INSTANCE}  << EOF   > $LOGDIR/$LOG_FILE
	drop view all_indexes ;
	exit;
EOF
}

#------------------------------------------
# Assign ACL
#------------------------------------------
Assign_ACL()
{
acl_user=$1
LOG_FILE=Tmp_Assign_ACL_to_${acl_user}_$$.log
sqlplus -s ${APP_USER}/${APP_PWD}@${PROD_INSTANCE}  << EOF   > $LOGDIR/$LOG_FILE
BEGIN
DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL('ACL_${acl_user}.xml','*');
END;
/
exit;
EOF
}

#-------------------
# Check_Rename_Tabs
#-------------------
Check_Rename_Tabs()
{
LIST_FILE=Check_Rename_Tabs_Ref_$$.lst
LOG_FILE=Check_Rename_Tabs_Ref_$$.log

sqlplus -s $CONNSTR  << EOF   > $WRKDIR/$LIST_FILE
	set lines 200 pages 0 trims on feedback off verify off head off
	select trim(object_name) from obj where object_name like 'Z%' and object_type='TABLE';
	exit;
EOF

LST=`cat $WRKDIR/$LIST_FILE`
for tab in $LST
do
	ForceRename $tab
done
}

#-------------------
# Force Rename
#-------------------
ForceRename()
{
SNAME=$1
STPRFX=`echo $SNAME | cut -d'_' -f1`
STPSFX=`echo $SNAME | cut -d'_' -f2-`
case ${STPRFX} in
    ZT) LONG_NAME="TABLE_${STPSFX}" ;;
    ZM) LONG_NAME="MTM_${STPSFX}" ;;
    *)echo "Table $SNAME Has Wrong Name, Force Renaming Reference Tables Back Has Failed"| tee -a $LOGFILE; Exit_Func;;
esac

sqlplus ${APP_USER}/${APP_PWD}@${PROD_INSTANCE} << EOF >> $LOGDIR/$LOG_FILE
set echo on feed on
drop synonym ${LONG_NAME};
rename ${SNAME} to ${LONG_NAME};
truncate table ${LONG_NAME};
insert into ${LONG_NAME} select * from ${ACTIVE_REF}.${LONG_NAME};
exit;
EOF

PREFIX=`
echo "  set echo off head off verify off feed off pages 0 lin 100
        select substr('${LONG_NAME}',1,(select instr('${LONG_NAME}','_') from dual)-1) from dual;
        exit;
"| sqlplus -s ${APP_USER}/${APP_PWD}@${PROD_INSTANCE}`

TYPE_NAME=`
echo "  set echo off head off verify off feed off pages 0 lin 100
        select lower((substr('${LONG_NAME}',(select instr('${LONG_NAME}','_') from dual)+1))) from dual;
        exit;
"| sqlplus -s ${APP_USER}/${APP_PWD}@${PROD_INSTANCE}`

if [ ${PREFIX} = TABLE ]
then
	sqlplus ${APP_USER}/${APP_PWD}@${PROD_INSTANCE} << EOF >> $LOGDIR/$LOG_FILE
	set echo on feed on
	update adp_tbl_oid set OBJ_NUM=(select nvl(max(objid),0)+1 from ${LONG_NAME}) where TYPE_ID in (select TYPE_ID from adp_object where TYPE_NAME='${TYPE_NAME}');
	delete adp_tbl_oid_unused where TYPE_ID in (select TYPE_ID from adp_object where TYPE_NAME='${TYPE_NAME}');
	exit;
EOF
fi

if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | $GREP "SP2-" | wc -l` -ne 0 ]
then
	echo "Error Renaming Table ${SNAME} from $APP_USER, which were moved from APP to REF or Dropped from CRM, Check $LOGDIR/$LOG_FILE"  | tee -a $LOGFILE
	\rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/DropSyn_SUCCESS
	Exit_Func
else
	echo "Warning - table ${SNAME} was force renamed to ${LONG_NAME}" | tee -a $LOGFILE
	\mv $WRKDIR/$LIST_FILE $WRKDIR/Tmp_$LIST_FILE
fi
}

#-------------------
# Check Z Mode - check if the z tableas are in the old convention
#-------------------
Check_Z_Mode()
{
COUNT_OLD_MODE=`
echo "  set echo off head off verify off feed off pages 0 lin 100
	select trim(count(*)) from TABS where TABLE_NAME like 'ZTABLE_%' or TABLE_NAME like 'ZMTM_%';
        exit;
"| sqlplus -s ${APP_USER}/${APP_PWD}@${PROD_INSTANCE}`
if [[ ${COUNT_OLD_MODE} -ne 0 ]];
then
	echo "Z Tables mode is old - run convert_Z_script.ksh to fix it" | tee -a $LOGFILE
	Exit_Func
fi
}

#-------------------
# Check ACL
#-------------------
Check_ACL()
{
LOG_FILE=Check_ACL_$$.log
sqlplus ${APP_USER}/${APP_PWD}@${PROD_INSTANCE} << EOF >> $LOGDIR/$LOG_FILE
set echo on feed on
select utl_inaddr.get_host_address('${HOST}') IPADDR from dual;
exit;
EOF
sqlplus $CONN/$CONN_PWD@$PROD_INSTANCE << EOF >> $LOGDIR/$LOG_FILE
set echo on feed on
select utl_inaddr.get_host_address('${HOST}') IPADDR from dual;
exit;
EOF
if [ `cat $LOGDIR/$LOG_FILE | $GREP "ORA-" | wc -l` -ne 0 ]
then
        echo "Error while check ACL permissions on $APP_USER and $CONN, Check $LOGDIR/$LOG_FILE"  | tee -a $LOGFILE
        Exit_Func
fi
}


########################################
#   MAIN
########################################

Set_Env
Set_Input
export STATUS=FAILURE
PARFILE=${CURDIR}/ParFile.par
if [ ! -f $PARFILE ]
#  then echo " File $PARFILE Does Not Exist. Create an example file (Y/N)?"
then echo " File $PARFILE Does Not Exist. Create an example file."
  Create_Par_File
fi

. $PARFILE

Check_ACL
Check_Fix_Mode
Check_Parameters
export CONNSTR=$APP_USER/$APP_PWD@$PROD_INSTANCE
Check_Z_Mode

echo "#####################################" >> $LOGFILE
echo " Working on Instance $PROD_INSTANCE" | tee -a $LOGFILE
echo "#####################################" >> $LOGFILE
REFLIST=ref_tables_list.lst

echo "------------------------------" >> $LOGFILE
echo " Handle CRM_REF_INFO issues   " >> $LOGFILE
echo "------------------------------" >> $LOGFILE
IS_CRM_INFO_TABLE_EXIST=`
echo "set echo off head off verify off feed off pages 0 lin 100
        SELECT count(*) FROM user_tables where table_name = 'CRM_REF_INFO';
        exit;
"| sqlplus -s $CONNSTR`
if [[ `echo ${IS_CRM_INFO_TABLE_EXIST}| $AWK '{FS=" "; print $1}'` = 0 ]];
  then echo " CRM_REF_INFO Table Does Not Exist, Creating it.   " | tee -a $LOGFILE
       Cre_Crm_Ref_Info_Table
fi

echo "-------------------------------------------------" >> $LOGFILE
echo " Define Active/Inactive Ref users and passwords  " >> $LOGFILE
echo "-------------------------------------------------" >> $LOGFILE
Define_Ref_Users

if [[ "$RUN_MODE" = "2" || "$RUN_MODE" = "5" ]]
  then echo "------------------------------------------------" >> $LOGFILE
       echo " Check Consistency Between the Ctl Table and Syn" >> $LOGFILE
       echo "------------------------------------------------" >> $LOGFILE
       if [[ "$FIX_MODE" = "N" ]]
       then
       Check_Ctl_Syn
       fi
fi


if [[ "$RUN_MODE" = "5" ]]
  then echo "---------------------------------" >> $LOGFILE
       echo " Check All Reference Tables Exist" >> $LOGFILE
       echo "---------------------------------" >> $LOGFILE
       Check_Ref_Exist
fi


if [[ "$RUN_MODE" = "1" || "$RUN_MODE" = "3" || "$RUN_MODE" = "4" ]]
  then if [[ "$DEL_CONFIRM" = "Y" ]]
         then echo "------------------------------" >> $LOGFILE
              echo " Export the Master Reference  " | tee -a $LOGFILE
              echo "------------------------------" >> $LOGFILE
              if [[ "${EXP_CONFIRM}" = "Y" ]]
                then echo " About to Export The Master Reference" | tee -a $LOGFILE
                     Do_Export
                     #To change tablespaces' names: perl -pe 's/TABLESPACE \"USERS\"/TABLESPACE \"CLARIFY_DATA_L\"/g' -pi $DMPDIR/$EXP_FILE.dmp
              fi

              echo "----------------" >> $LOGFILE
              echo " Clean Schemas  " | tee -a $LOGFILE
              echo "----------------" >> $LOGFILE

	      #TABLE_EXIST_TABLE_CONFIG_ITM=`
	      #echo "  set echo off head off verify off feed off pages 0 lin 100
              #      select TABLE_NAME from TABS where TABLE_NAME='TABLE_CONFIG_ITM';
              #           exit;
		#    "| sqlplus -s $ACTIVE_REF/$ACTIVE_REF_PWD@$PROD_INSTANCE`

              echo "--------------------------------------------" >> $LOGFILE
              echo " Import into the Reference Account  " | tee -a $LOGFILE
              echo "--------------------------------------------" >> $LOGFILE

	      Check_If_Done Do_Import
	      if [ $? -eq 1 ]
              then
              	Do_Import
	      else
								echo "Fix MODE - Do_Import Skipped" | tee -a $LOGFILE
	      fi
       fi

       if [[ "$DAT_CONFIRM1" = "Y" ]]
         then echo "---------------------------------------------" >> $LOGFILE
              echo " Run *.dat or *.sql Files on Reference User  " | tee -a $LOGFILE
              echo "---------------------------------------------" >> $LOGFILE
              LST=`cat $LOGDIR/$DAT_LOCATION1`
              for each in $LST
              do
                  echo $each | $GREP -q "\.dat$"
                  if [ $? -ne 0 ]
                    then Run_Sqlplus $NON_ACTIVE_REF $NON_ACTIVE_REF_PWD $each sqlplus_ref_$$.log
                    else Run_Dataex $NON_ACTIVE_REF $NON_ACTIVE_REF_PWD $each dataex_ref_$$.log
                  fi
              done
       fi

       if [[ "$DEL_CONFIRM" = "Y" || "$DAT_CONFIRM1" = "Y" ]]
         then echo "-------------------------" >> $LOGFILE
         #     echo " Handle the UPD tables   " | tee -a $LOGFILE
         #     echo "-------------------------" >> $LOGFILE
         #     Handle_UPD
         #     if [[ "$TABLE_EXIST_TABLE_CONFIG_ITM" = "TABLE_CONFIG_ITM" ]]
	 #     then
              echo "---------------------------" >> $LOGFILE
              echo " Update table_config_item  " | tee -a $LOGFILE
              echo "---------------------------" >> $LOGFILE
              Upd_Config_Itm $NON_ACTIVE_REF/$NON_ACTIVE_REF_PWD@$PROD_INSTANCE
	#     fi
              Upd_Num_Scheme

              echo "------------------------------" >> $LOGFILE
              echo " Handle the reference grants  " | tee -a $LOGFILE
              echo "------------------------------" >> $LOGFILE
              Create_Grants $NON_ACTIVE_REF/$NON_ACTIVE_REF_PWD@$PROD_INSTANCE $APP_USER
              Revoke_Unnecessary_Grants $NON_ACTIVE_REF/$NON_ACTIVE_REF_PWD@$PROD_INSTANCE $NON_ACTIVE_REF
       fi
fi

if [[ "$RUN_MODE" = "1" || "$RUN_MODE" = "2" ]] #1
  then echo "-------------------------------------------------------" >> $LOGFILE
       echo " Drop Synonyms to Reference and Create Tables instead  " | tee -a $LOGFILE
       echo "-------------------------------------------------------" >> $LOGFILE

				Check_If_Done DropSyn
        if [ $? -eq 1 ] #2
        then
        	DropSyn
        	ReturnRefTabs
        else
        	echo "Fix MODE - DropSyn Skipped" | tee -a $LOGFILE
        fi #2

       if [[ "${DAT_CONFIRM2}" = Y ]] #2
         then echo "----------------------------------------------" >> $LOGFILE
              echo " Run *.dat or *.sql Files on Application User  " | tee -a $LOGFILE
              echo "----------------------------------------------" >> $LOGFILE
              LST=`cat $LOGDIR/$DAT_LOCATION2`
              for each in $LST
              do
                  echo $each | $GREP -q "\.dat$"
                  if [ $? -ne 0 ]
                    then Run_Sqlplus $APP_USER $APP_PWD $each sqlplus_app_$$.log
                    else Run_Dataex $APP_USER $APP_PWD $each dataex_app_$$.log
                  fi
              done
       fi #2

       if [[ "${XML_CONFIRM}" = Y ]] #3
       then
       	echo "----------------------" >> $LOGFILE
        echo " Run Schema XML file  " | tee -a $LOGFILE
        echo "----------------------" >> $LOGFILE
				Check_If_Done Run_XML_Schema
        if [ $? -eq 0 ] #4
        then
                echo "Fix MODE - Run_XML_Schema Skipped" | tee -a $LOGFILE
				else
	     				touch ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/Run_XML_Schema_SUCCESS
	     				Cre_Tab_All_Indexes
					##Assign_ACL SA
							Delete_Views
	      			$XML_COMMAND
              if [ `cat $LOGDIR/trace_file.log | $GREP "ORA-" | wc -l` -ne 0 ] #5
              then
              			echo " There was a Problem in running the xml file, please check $LOGDIR/trace_file.log "
										\rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/Run_XML_Schema_SUCCESS
                    Exit_Func
              elif [ `cat $LOGDIR/trace_file.log | $GREP "Java Error: java.lang.ClassCastException: java.lang.NullPointerException incompatible with com.clarify.cbo.CboError" | wc -l` -ne 0 ]
              then
              			echo " There was a Problem in running the xml file, please check $LOGDIR/trace_file.log "
										\rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/Run_XML_Schema_SUCCESS
                    Exit_Func
              elif [ `cat $LOGDIR/trace_file.log | $GREP "An unexpected error has been detected by HotSpot Virtual Machine" | wc -l` -ne 0 ]
              then
              			echo " There was a Problem in running the xml file, please check $LOGDIR/trace_file.log "
										\rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/Run_XML_Schema_SUCCESS
                    Exit_Func
              elif [ `cat $LOGDIR/trace_file.log | $GREP "CBO Error:" | wc -l` -ne 0 ]
      				then
      							echo " There was a Problem in running the xml file, please check $LOGDIR/trace_file.log "
										\rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/Run_XML_Schema_SUCCESS
     								Exit_Func
              elif [ `cat $LOGDIR/trace_file.log | $GREP "Java Error: " | wc -l` -ne 0 ]
              then
              			echo " There was a Problem in running the xml file, please check $LOGDIR/trace_file.log "
										\rm -f ${WRKDIR}/${PROD_INSTANCE}_IS_ON_PROCESS/Run_XML_Schema_SUCCESS
                    Exit_Func
              else
              			echo " objectSchema.xml executed successfully on $APP_USER " | tee -a $LOGFILE
		 								mv $LOGDIR/trace_file.log $LOGDIR/trace_file_$$_${PROD_INSTANCE}.log
              fi  #5
        fi #4
       fi #3
       echo "---------------------------------" >> $LOGFILE
       echo " Handle New Indexes and Triggers - x_dbtune   " | tee -a $LOGFILE
       echo "---------------------------------" >> $LOGFILE
       RunXDbtune
fi #1

if [[ "$RUN_MODE" = "1" || "$RUN_MODE" = "2" || "$RUN_MODE" = "3" ]]
  then
  		 echo "--------------------------------------" >> $LOGFILE
       echo " Rename Reference tables on App User  " | tee -a $LOGFILE
       echo "--------------------------------------" >> $LOGFILE
			 Check_If_Done RenameTabs
       if [ $? -eq 1 ]
       then
                RenameTabs
       else
                echo "Fix MODE - RenameTabs Skipped" | tee -a $LOGFILE
       fi
fi

if [[ "$RUN_MODE" = "1" || "$RUN_MODE" = "2" ]]
  then echo "------------------------" >> $LOGFILE
       echo " Drop Public Synonyms   " | tee -a $LOGFILE
       echo "------------------------" >> $LOGFILE
       Drop_Pub_Syn $APP_USER $APP_PWD
       Drop_Pub_Syn $NON_ACTIVE_REF $NON_ACTIVE_REF_PWD
       echo "------------------------" >> $LOGFILE
       echo " Drop Public Grants   " | tee -a $LOGFILE
       echo "------------------------" >> $LOGFILE
       Rvk_Grants_Pub $NON_ACTIVE_REF $NON_ACTIVE_REF_PWD
       Rvk_Grants_Pub $APP_USER $APP_PWD
fi

if [[ "$RUN_MODE" = "1" || "$RUN_MODE" = "2" || "$RUN_MODE" = "3" || "$RUN_MODE" = "5" ]]
  then echo "--------------------------------" >> $LOGFILE
       echo " Create Synonyms to Reference   " | tee -a $LOGFILE
       echo "--------------------------------" >> $LOGFILE
			  Check_If_Done CreateSyn
        if [ $? -eq 1 ]
        then
                CreateSyn
        else
                echo "Fix MODE - CreateSyn Skipped" | tee -a $LOGFILE
        fi

       echo "------------------------------------" >> $LOGFILE
       echo " Handle sacon synonyms  " | tee -a $LOGFILE
       echo "------------------------------------" >> $LOGFILE
       PrepareSyn
       RunSyn

       echo "----------------" >> $LOGFILE
       echo " Compile Views  " | tee -a $LOGFILE
       echo "----------------" >> $LOGFILE
       Compile_Views $APP_USER $APP_PWD
       Compile_Views $NON_ACTIVE_REF $NON_ACTIVE_REF_PWD

       echo "------------------------------------"
       echo " Compile all other invalid objects  " | tee -a $LOGFILE
       echo "------------------------------------"
       CompileObj $APP_USER $APP_PWD
       CompileObj $CONN $CONN_PWD
       CompileObj $NON_ACTIVE_REF $NON_ACTIVE_REF_PWD

       echo "---------------------------------------------------   "
       echo " Grant Core sequences MESSAGE_SEQ and BG_ACTION_SEQ   " | tee -a $LOGFILE
       echo "---------------------------------------------------   "
       GrantSeq $APP_USER $APP_PWD

       echo "-------------------------------------" >> $LOGFILE
       echo " Run Statistics on reference tables  " >> $LOGFILE
       echo "-------------------------------------" >> $LOGFILE
       LST=`cat $REFLIST`
       Run_Stat $NON_ACTIVE_REF $CONNSTR
fi

if [[ "$RUN_MODE" = "1" || "$RUN_MODE" = "3" || "$RUN_MODE" = "5" ]]
  then echo "----------------------------" >> $LOGFILE
       echo " Update CRM_REF_INFO table  " | tee -a $LOGFILE
       echo "----------------------------" >> $LOGFILE
       Upd_Crm_Ref_Info_Table
fi

printf "***********************************************\n" | tee -a $LOGFILE
echo " The RefreshDatabase Process Ended Successfully!  " | tee -a $LOGFILE
echo "***********************************************" | tee -a $LOGFILE
export STATUS=SUCCESS
Exit_Func

## 16-8-2011 - adjust to linux (itsik)
## 29-11-2011 - support short names for z tables + ACL Check(itsik)
## 19-01-2012 - AIF_OPERATION moved to ref
