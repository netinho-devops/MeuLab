#!/usr/bin/ksh

if [[ `uname` = Linux ]]
then
	export ksh_version=`ksh --version 2>&1 | grep 93t`
	if [[ "$ksh_version" != "" ]]	
	then
	        alias echo='/bin/echo -e'
	fi
fi

ExitProc ()
{
case $1 in
     1) echo "failed to connect to $2";;
     2) echo "Usage  :  check_env_ver.ksh <ENV_CODE> \n example: check_env_ver.ksh BMH6" ;;
     3) ;; 
     
esac

exit $1
}

Check_Env ()
{

tmp_file=/tmp/tmp_$4_file_$timestamp
log_file=/tmp/log_$4_file_$timestamp
touch $log_file
empty_flag=0;
#module=750;

echo "set verify off line 200;\n select env_code, module_version, max(patch_id) from db_environment_details where env_code = upper('$2')  group by env_code, module_version;" | sqlplus -s $1  >> $tmp_file
echo "set verify off line 200;\n col password format a20 ;\n col username format a20;\n select ENV_PROFILE from DB_ENVIRONMENT_LIST where env_code=upper('$2');" | sqlplus -s $1 >> $tmp_file
echo "set verify off line 200;\n col password format a20 ;\n col username format a20;\n select distinct username,password, db_instance from dbconfig where env_code=upper('$2');" | sqlplus -s $1 >> $tmp_file


err_flag=`grep -c "ORA-" $tmp_file` 

if [[ $err_flag -gt 0 ]]
then
   ExitProc 1 $1
fi


empty_flag=`grep -c "no rows" $tmp_file ` 
#echo "empty_flag : " $empty_flag
if [[ $empty_flag -eq 0 ]]
then   
   echo "\n\n===================  OUTPUT  ========================" >$log_file
   echo "Tiger repository : $1 \nURL : $3" >> $log_file   
   cat $tmp_file >> $log_file   
   cat $log_file >> $log_file_all
fi
rm -f $tmp_file
#echo "eof"
#clear
#cat $log_file
#rm -f $log_file
#ExitProc 3
}

if [ $# -lt 1 ]
then
  ExitProc 2
fi
timestamp=`date '+%m%d%y_%H_%M_%S'`
log_file_all=/tmp/log_file_all_$timestamp
touch $log_file_all
echo "Checking..."
Check_Env tiger_rep_abp/tiger_rep_abp@bsstools $1 "http://illin1339:16600" 1 
Check_Env tiger_rep_oms/tiger_rep_oms@bsstools $1 "http://illin1339:16700" 1 
Check_Env tiger_rep_se/tiger_rep_se@bsstools $1 "http://illin1339:16800" 1 
Check_Env tiger_rep_amss/tiger_rep_amss@bsstools $1 "http://illin1339:16900" 1 
Check_Env tiger_rep_prm/tiger_rep_prm@bsstools $1 "http://illin1339:17000" 1 
#Check_Env TIGER_CONN/TIGER_CONN@RMTGI810 $1 "http://illin417:8888/" 1 &
#Check_Env tiger_conn/tiger_conn@TGR11ABP $1 "http://illin345:8888" 4 &
wait

#clear
cat $log_file_all
rm -f $log_file_all
echo " ================  END ================================="
