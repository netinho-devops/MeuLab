#!/bin/ksh

Env_Code=$1

ABP_CONNSTR=TIGER_REP_ABP/TIGER_REP_ABP@VV9TOOLS
MCSS_CONNSTR=TIGER_REP_ECR/TIGER_REP_ECR@VV9TOOLS

AMSSEnv_Details=`
     echo " set echo off head off verify off feed off pages 0 lin 120
     SELECT DISTINCT username,PASSWORD,db_instance from dbconfig where  ENV_CODE='${Env_Code}' and username like '%DB%' and username not like '%DBO%' and username not in ('AIM_DBA');
     exit;
     " | sqlplus -s ${MCSS_CONNSTR} `

export AMSSEnvProfile=`
echo "  set echo off head off verify off feed off pages 0 lin 120
        select distinct ENV_PROFILE
        from DB_ENVIRONMENT_LIST
        where env_code = '${Env_Code}';
        exit;
        " | sqlplus -s ${MCSS_CONNSTR} `


export ABPEnvProfile=`
echo "  set echo off head off verify off feed off pages 0 lin 120
        select distinct ENV_PROFILE
        from DB_ENVIRONMENT_LIST
        where env_code = '${Env_Code}';
        exit;
        " | sqlplus -s ${ABP_CONNSTR} `

if [[ ${ABPEnvProfile} = "TEST_OWN_CFG" ]];then

ABP_Env_Details=`
     echo " set echo off head off verify off feed off pages 0 lin 120
     SELECT DISTINCT username,PASSWORD,db_instance from dbconfig where  ENV_CODE='${Env_Code}' and username like '%APP%' and username not like '%APPO%';
     exit;
     " | sqlplus -s ${ABP_CONNSTR} `

ABP_REF_Details=`
                echo " set echo off head off verify off feed off pages 0 lin 120
                SELECT DISTINCT username,PASSWORD,db_instance from dbconfig where  ENV_CODE='${Env_Code}' and username like '%REF%' and DB_USER_TYPE='N';
                exit;
                " | sqlplus -s ${ABP_CONNSTR} `
else


ABP_Env_Details=`
     echo " set echo off head off verify off feed off pages 0 lin 120
     SELECT DISTINCT username,PASSWORD,db_instance from dbconfig where  ENV_CODE='${Env_Code}' and username like '%DB%' and username not like '%DBO%' and username not in ('AIM_DBA');
     exit;
     " | sqlplus -s ${ABP_CONNSTR} `

ABP_REF_Details=`
     echo " set echo off head off verify off feed off pages 0 lin 120
     SELECT DISTINCT username,PASSWORD,db_instance from dbconfig where  ENV_CODE='${Env_Code}' and username like '%DB%' and DB_USER_TYPE='N';
     exit;
     " | sqlplus -s ${ABP_CONNSTR} `


fi

USERNAME_DB=`echo $AMSSEnv_Details | awk '{FS=" "; print $1}'`
PASSWORD_DB=`echo $AMSSEnv_Details | awk '{FS=" "; print $2}'`
INSTANCE_DB=`echo $AMSSEnv_Details | awk '{FS=" "; print $3}'`

USERNAME_ABPAPP=`echo $ABP_Env_Details | awk '{FS=" "; print $1}'`
PASSWORD_ABPAPP=`echo $ABP_Env_Details | awk '{FS=" "; print $2}'`
INSTANCE_ABPAPP=`echo $ABP_Env_Details | awk '{FS=" "; print $3}'`

USERNAME_ABPREF=`echo $ABP_REF_Details | awk '{FS=" "; print $1}'`
PASSWORD_ABPREF=`echo $ABP_REF_Details | awk '{FS=" "; print $2}'`
INSTANCE_ABPREF=`echo $ABP_REF_Details | awk '{FS=" "; print $3}'`



if [[ ${AMSSEnvProfile} = "TEST_RDM" ]];then

	exists=`
    	 echo " set echo off head off verify off feed off pages 0 lin 120
     	SELECT count(*) from user_db_links where DB_LINK='ABPDL';
     	exit;
     	" | sqlplus -s ${USERNAME_DB}/${PASSWORD_DB}@${INSTANCE_DB} `

	if [[ ${exists} -eq 0 ]];then

		echo "
		CREATE DATABASE LINK ABPDL CONNECT TO ${USERNAME_ABPAPP} IDENTIFIED BY ${PASSWORD_ABPAPP} USING '${INSTANCE_ABPAPP}';
		create OR REPLACE synonym ECR9_REF_DEVICE_RATE for ${USERNAME_ABPAPP}.PC9_DEVICE_RATE@ABPDL;
		exit;
		" | sqlplus -s ${USERNAME_DB}/${PASSWORD_DB}@${INSTANCE_DB}
	else
        echo "
		DROP DATABASE LINK ABPDL;
        CREATE DATABASE LINK ABPDL CONNECT TO ${USERNAME_ABPAPP} IDENTIFIED BY ${PASSWORD_ABPAPP} USING '${INSTANCE_ABPAPP}';
        create OR REPLACE synonym ECR9_REF_DEVICE_RATE for ${USERNAME_ABPAPP}.PC9_DEVICE_RATE@ABPDL;
        exit;
        " | sqlplus -s ${USERNAME_DB}/${PASSWORD_DB}@${INSTANCE_DB}
	fi

    exists=`
         echo " set echo off head off verify off feed off pages 0 lin 120
        SELECT count(*) from user_db_links where DB_LINK='MCSS_TO_ABP';
        exit;
        " | sqlplus -s ${USERNAME_DB}/${PASSWORD_DB}@${INSTANCE_DB} `

    if [[ ${exists} -eq 0 ]];then

		echo "
		CREATE DATABASE LINK MCSS_TO_ABP CONNECT TO ${USERNAME_ABPREF} IDENTIFIED BY ${PASSWORD_ABPREF} USING '${INSTANCE_ABPREF}';
		create or replace synonym bl1_message_text for ${USERNAME_ABPREF}.bl1_message_text@MCSS_TO_ABP;
		create or replace synonym bl1_charge_code for ${USERNAME_ABPREF}.bl1_charge_code@MCSS_TO_ABP;
		create or replace synonym add9_bill_section_text for ${USERNAME_ABPREF}.add9_bill_section_text@MCSS_TO_ABP;
		create or replace synonym GetDyna for ${USERNAME_ABPREF}.GetDyna@MCSS_TO_ABP;
		exit;
		" | sqlplus -s ${USERNAME_DB}/${PASSWORD_DB}@${INSTANCE_DB} 
	else
       echo "
		DROP DATABASE LINK MCSS_TO_ABP;
        CREATE DATABASE LINK MCSS_TO_ABP CONNECT TO ${USERNAME_ABPREF} IDENTIFIED BY ${PASSWORD_ABPREF} USING '${INSTANCE_ABPREF}';
        create or replace synonym bl1_message_text for ${USERNAME_ABPREF}.bl1_message_text@MCSS_TO_ABP;
        create or replace synonym bl1_charge_code for ${USERNAME_ABPREF}.bl1_charge_code@MCSS_TO_ABP;
        create or replace synonym add9_bill_section_text for ${USERNAME_ABPREF}.add9_bill_section_text@MCSS_TO_ABP;
        create or replace synonym GetDyna for ${USERNAME_ABPREF}.GetDyna@MCSS_TO_ABP;
        exit;
        " | sqlplus -s ${USERNAME_DB}/${PASSWORD_DB}@${INSTANCE_DB} 
	fi	
fi

