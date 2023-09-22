#!/bin/ksh

SCRIPTS_HOME=~vivtools/Scripts/License_Checker/CRM_Lic_Alert
PROPERTY_FILE=${SCRIPTS_HOME}/CRM_lists
BATCH_MODE=$1

check_env_type ()
{
export ENV_TYPE=`echo ${1} | cut -d'.' -f2`
}

#echo "set serveroutput on;
#set feedback off;
#set termout off;
#
#declare
#  v_lic varchar2(32767); i number := 1; j number;
#begin
#  v_lic := pkgsession.getlicense;
#
#  loop
#    j := instr(v_lic,chr(13),i);
#        exit when j=0;
#        if j-i < 81 then
#      dbms_output.put_line(substr(v_lic,i,j-i));
#      i:= j+2;
#        else
#      dbms_output.put_line(substr(v_lic,i,80));
#      i:= i+80;
#        end if;
#  end loop;
#  v_lic := substr(v_lic,i); i:=1;
#  while i<length(v_lic) loop
#        dbms_output.put_line(substr(v_lic,i,80));
#    i:= i+80;
#  end loop;
#end;
#/
#exit;
#" > ${SCRIPTS_HOME}/Check_Lic.sql

cat ${PROPERTY_FILE} | grep -v ^# | grep ^lic >> ${SCRIPTS_HOME}/tmp/liccheckenv.txt
LIC_PROPERTY=${SCRIPTS_HOME}/tmp/liccheckenv.txt

run_lic_check()
{
	DB_SID=`echo ${1} | cut -d'.' -f2`
	DB_HOST=`tnsping ${DB_SID} | grep host | cut -d"(" -f5 | cut -d")" -f1 | cut -d'=' -f2`
	
#select LICENSE_TYPE, COMPANY_NAME,ISSUE_DATE,EXPIRATION_DATE,DB_INSTANCE_NAME from TABLE_LIC_TYPES;
#@${SCRIPTS_HOME}/Check_Lic.sql
sqlplus -s -L sa/sa@${DB_SID} << eof
spool ${SCRIPTS_HOME}/tmp/lic.txt
@${SCRIPTS_HOME}/Check_Lic.sql
spool off;
eof

        if [[ $? != 0 ]] 
	then
cat << EOL
	                         <ROW>
                                        <DATA>${DB_SID}</DATA>
                                        <DATA>${ENV_TYPE}</DATA>
                                        <DATA>${DB_HOST}</DATA>
					<DATA>ERROR: Can't connect to DB</DATA>
					<DATA>ERROR: Can't connect to DB</DATA>
					<DATA>UNKNOWN</DATA>
                                </ROW>
EOL
        else

		#EXPIRY_DATE=$(grep onViolation ${SCRIPTS_HOME}/tmp/lic.txt |head -1 | cut -d">" -f2|cut -d"<" -f1);
		EXPIRY_DATE=$(tail -1 ${SCRIPTS_HOME}/tmp/lic.txt | cut -d" " -f1)
		#EXPR_DATE=$(grep onViolation ${SCRIPTS_HOME}/tmp/lic.txt |head -1 | cut -d">" -f2|cut -d"<" -f1 | awk 'BEGIN{FS="/";OFS="-"}{print $3,$2,$1}');
		EXPR_DATE="today" #for debug only , must be implemented!
		#LICENSED_IP=$(grep onViolation ${SCRIPTS_HOME}/tmp/lic.txt |tail -1 | cut -d">" -f2|cut -d"<" -f1);
		LICENSED_IP=${DB_SID} #for debug only , must be implemented!

			
                #if [[ $EXPR_DATE = [0-9]* ]]
                if [[ $EXPIRY_DATE = [0-9]* ]]
		then

		DAY=`date +%d`
		MONTH=`date +%m`
		YEAR=`date +%Y`


		export DAY_BEFORE="$YEAR-$MONTH-$DAY"
		DAYS_LEFT=`getdatediff.pl $EXPIRY_DATE` 
						
                        if [[ $((  $(echo $EXPIRY_DATE | tr -d '-')  -  $(echo $DAY_BEFORE | tr -d '-')  )) -ge 0 ]] ; then
cat << EOL
                               		 <ROW>
                                       		<DATA>${DB_SID}</DATA>
                                        	<DATA>${ENV_TYPE}</DATA>
                                       		<DATA>${DB_HOST}</DATA>
                                        	<DATA>${EXPIRY_DATE}</DATA>
                                        	<DATA>${LICENSED_IP}</DATA>
						<DATA>N</DATA>
						<DATA>$DAYS_LEFT</DATA>
					</ROW>
EOL
                        else
cat << EOL
                                         <ROW>
                                                <DATA>${DB_SID}</DATA>
                                                <DATA>${ENV_TYPE}</DATA>
                                                <DATA>${DB_HOST}</DATA>
                                                <DATA>License has expired on:${EXPR_DATE}</DATA>
                                                <DATA>${LICENSED_IP}</DATA>
						<DATA>Y</DATA>
                                         </ROW>
EOL
                        fi

                

                else
cat << EOL
                                         <ROW>
                                                <DATA>${DB_SID}</DATA>
                                                <DATA>${ENV_TYPE}</DATA>
                                                <DATA>${DB_HOST}</DATA>
                                                <DATA>ERROR in fetching license data</DATA>
                                                <DATA>ERROR in fetching license data</DATA>
                                         </ROW>
EOL
	
                fi
	fi
}

print_invalid_env()
{
        DB_SID=`echo ${1} | cut -d'.' -f2`
        DB_HOST=`tnsping ${DB_SID} | grep host | cut -d"(" -f5 | cut -d")" -f1 | cut -d'=' -f2`
cat << EOL
                                         <ROW>
                                                <DATA>${DB_SID}</DATA>
                                                <DATA>INVALID env type</DATA>
                                                <DATA>${DB_HOST}</DATA>
                                                <DATA>ERROR in fetching license data</DATA>
                                                <DATA>ERROR in fetching license data</DATA>
                                         </ROW>
EOL
}

PrintXML()
{

cat << EOF
        <ROOT>
                <NAME>License Status</NAME>
                <BODY>
                        <TABLE>
                                <HEADER_ROW>
                                        <HEADER>Environment</HEADER>
                                        <HEADER>Environment type</HEADER>
					<HEADER>DB server</HEADER>
                                        <HEADER>License Expiry Date</HEADER>
                                        <HEADER>Licensed DB server IP</HEADER>
					<HEADER>Expired</HEADER>	
					<HEADER type="number">Days left</HEADER>				
                                </HEADER_ROW>
EOF

for entry in `cat ${LIC_PROPERTY}`
do
	check_env_type $entry
        run_lic_check $entry
done

cat << EOF
                        </TABLE>
                  </BODY>
                <STATUS/>
               <ICON/>
        </ROOT>
EOF
}

run_lic_check_Batch()
{
	DB_SID=`echo ${1} | cut -d'.' -f2`
	DB_HOST=`tnsping ${DB_SID} | grep host | cut -d"(" -f5 | cut -d")" -f1 | cut -d'=' -f2`
	
sqlplus -s -L sa/sa@${DB_SID} << eof
spool ${SCRIPTS_HOME}/tmp/lic.txt
@${SCRIPTS_HOME}/Check_Lic.sql
spool off;
eof

        if [[ $? != 0 ]] 
	then
cat << EOL
	                         <ROW>
                                        <DATA>${DB_SID}</DATA>
                                        <DATA>${ENV_TYPE}</DATA>
                                        <DATA>${DB_HOST}</DATA>
					<DATA>ERROR: Can't connect to DB</DATA>
					<DATA>ERROR: Can't connect to DB</DATA>
					<DATA>UNKNOWN</DATA>
                                </ROW>
EOL
        else

		#EXPIRY_DATE=$(grep onViolation ${SCRIPTS_HOME}/tmp/lic.txt |head -1 | cut -d">" -f2|cut -d"<" -f1);
		EXPIRY_DATE=$(tail -1 ${SCRIPTS_HOME}/tmp/lic.txt | cut -d" " -f1)
		#EXPR_DATE=$(grep onViolation ${SCRIPTS_HOME}/tmp/lic.txt |head -1 | cut -d">" -f2|cut -d"<" -f1 | awk 'BEGIN{FS="/";OFS="-"}{print $3,$2,$1}');
		EXPR_DATE="today" #for debug only , must be implemented!
		#LICENSED_IP=$(grep onViolation ${SCRIPTS_HOME}/tmp/lic.txt |tail -1 | cut -d">" -f2|cut -d"<" -f1);
		LICENSED_IP=${DB_SID} #for debug only , must be implemented!

			
                #if [[ $EXPR_DATE = [0-9]* ]]
                if [[ $EXPIRY_DATE = [0-9]* ]]
		then

		DAY=`date +%d`
		MONTH=`date +%m`
		YEAR=`date +%Y`


		export DAY_BEFORE="$YEAR-$MONTH-$DAY"
		DAYS_LEFT=`getdatediff.pl $EXPIRY_DATE` 
						
                        if [[ $((  $(echo $EXPIRY_DATE | tr -d '-')  -  $(echo $DAY_BEFORE | tr -d '-')  )) -gt 45 ]] ; then
cat << EOL
           
  Working CRM Environemnt ${DB_SID} On Server ${DB_HOST} exipiring on ${EXPIRY_DATE} Days_Left=$DAYS_LEFT
EOL
                        else
cat << EOL
  PROBLEM CRM Environemnt ${DB_SID}  On Server ${DB_HOST} exipiring on ${EXPIRY_DATE} Days_Left=$DAYS_LEFT   
EOL
  							        fi     
	      fi
	fi	

}


PrintBatch()
{

for entry in `cat ${LIC_PROPERTY}`
	do
		check_env_type $entry
                run_lic_check_Batch $entry
	done

}

if [ "${BATCH_MODE}" != "Batch" ] ;then
	PrintXML
else
	echo "BAtch"
	PrintBatch
fi
rm -f  ${SCRIPTS_HOME}/tmp/liccheckenv.txt

