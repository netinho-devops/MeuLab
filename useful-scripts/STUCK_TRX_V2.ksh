#!/usr/bin/ksh

Version="V2  "
CBP_ID=""
LDResult=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
SELECT LOGICAL_DATE AS LD FROM LOGICAL_DATE WHERE expiration_date is null and LOGICAL_DATE_TYPE='O';
exit;
END`

########################################
clear
echo "\n\n\n\n"
clear
echo "\n"
echo "\033[44m ************************************* "
echo "\033[44m   Stuck TRX                           "
echo "\033[44m   Creator: Luis Eduardo de Freitas    "
echo "\033[44m   Project: TEF GLX                    "
echo "\033[44m   Version: $Version                       "
echo "\033[44m   Date:    $(date "+%d-%b-%Y,%T-%Z")   "
echo "\033[44m   Logical Date: "$LDResult"             "
echo "\033[44m ************************************* \033[0m \n"

######Checks for TRB1MANAGER
st=`ps -fu $USER | grep "TRB1Manager" |grep -v grep |wc -l`

if [ $st -ne 1 ]
 then
      echo "=========================================================="
      echo " TRB1Manager is \033[41m DOWN \033[0m, please check the reason"
      echo "=========================================================="
 else
      echo "=================="
      echo " TRB1Manager $(tput setaf 2) UP $(tput sgr0)"
      echo "=================="
fi
######Checks for TRB1MANAGER

######Checks for APINVOKER 1
st=`ps -fu $USER | grep "amc1_DmnEnvelope TLS1_APInvoker_1_1" |grep -v grep |wc -l`

if [ $st -ne 1 ]
 then
     echo "======================================================="
     echo " TLS1APINV_1 is \033[41m DOWN \033[0m, please check the reason"
     echo "======================================================="
 else
     echo "=================="
     echo " TLS1APINV_1 $(tput setaf 2) UP $(tput sgr0)"
     echo "=================="
fi
######Checks for APINVOKER 1

######Checks for APINVOKER 2
st=`ps -fu $USER | grep "amc1_DmnEnvelope TLS1_APInvoker_2_1" |grep -v grep |wc -l`

if [ $st -ne 1 ]
 then
     echo "======================================================="
     echo " TLS1APINV_2 is \033[41m DOWN \033[0m, please check the reason"
     echo "======================================================="
 else
     echo "=================="
     echo " TLS1APINV_2 $(tput setaf 2) UP $(tput sgr0)"
     echo "=================="
fi
######Checks for APINVOKER 2

######Checks for APINVOKER 10
st=`ps -fu $USER | grep "amc1_DmnEnvelope TLS1_APInvoker_10_1" |grep -v grep |wc -l`

if [ $st -ne 1 ]
 then
     echo "======================================================="
     echo " TLS1APINV_10 is \033[41m DOWN \033[0m, please check the reason"
     echo "======================================================="
 else
     echo "=================="
     echo " TLS1APINV_10 $(tput setaf 2) UP $(tput sgr0)"
     echo "=================="
fi
######Checks for APINVOKER 10

######Checks for BL1BTLSOR
checkjob=`ps -fu $USER | grep BL1BTLSOR |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`

if [ $checkjob -ne 1 ]
 then
     echo "=========================================================="
     echo " BL BTLSOR is \033[41m DOWN \033[0m, please check the reason"
     echo "=========================================================="
 else
     echo "=================="
     echo " BL BTLSOR $(tput setaf 2) UP $(tput sgr0)"
     echo "=================="
fi
######Checks for BL1BTLSOR

######Checks for TC UH Rating
checkjob=`ps -fu $USER | grep UHI_RT547 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`

if [ $checkjob -ne 1 ]
 then
     echo "=========================================================="
     echo " UHI_RT547 is \033[41m DOWN \033[0m, please check the reason"
     echo "=========================================================="
 else
     echo "=================="
     echo " UHI_RT547 $(tput setaf 2) UP $(tput sgr0)"
     echo "=================="
fi
######Checks for TC UH Rating

######Checks for TC UH Guiding
checkjob=`ps -fu $USER | grep UHI_GD537 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`

if [ $checkjob -ne 1 ]
 then
     echo "=========================================================="
     echo " UHI_GD537 is \033[41m DOWN \033[0m, please check the reason"
     echo "=========================================================="
 else
     echo "=================="
     echo " UHI_GD537 $(tput setaf 2) UP $(tput sgr0)"
     echo "=================="
fi
######Checks for TC UH Guiding

########################################

echo "\n$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
read menu

########################
#Stuck TRX Main Menu#
########################
main_menu() {

        clear
        
        Menu=0
									
        while [[ $Menu -ne 99 ]] do
								clear
								echo "$(tput bold)========================================="
        				echo "$(tput bold)|     	 	Stuck TRX  	   	|"
        				echo "$(tput bold)========================================="
        				echo "\n$(tput bold)Stuck Transactions Manager Script$(tput sgr0)"
        				echo ""
                echo "========================================="
                echo ""
                echo "Choose an option:"
                echo ""
                echo "Tables:"
                echo "$(tput bold)[1] $(tput sgr0)- TRB1_PUB_LOG"
                echo "$(tput bold)[2] $(tput sgr0)- TRB1_SUB_LOG"
                echo "$(tput bold)[3] $(tput sgr0)- TRB1_SUB_ERRS"
                echo ""
                echo "========================================="
                echo ""
                echo "Daemons & Jobs:"
                echo ""
                echo "$(tput bold)[4] $(tput sgr0)- TRB1MANAGER"
                echo "$(tput bold)[5] $(tput sgr0)- TLS API INVOKER 1"
                echo "$(tput bold)[6] $(tput sgr0)- CL API INVOKER"
                echo "$(tput bold)[7] $(tput sgr0)- TLS API INVOKER 10"
                echo "$(tput bold)[8] $(tput sgr0)- BL BTLSOR"
                echo "$(tput bold)[9] $(tput sgr0)- TC UH Rating"
                echo "$(tput bold)[10] $(tput sgr0)- TC UH Guiding"
                echo "$(tput bold)[11] $(tput sgr0)- ADJ1CYCMN"
                echo "$(tput bold)$(tput setaf 1)[99] $(tput sgr0)$(tput setaf 1)- Exit Script$(tput sgr0)"
                echo ""
                read Menu?'Chosen Option: '

            
                case $Menu in
								1) echo "\n1 - TRB1_PUB_LOG\n" 
								retrieveTRXPub;;
								2) echo "\n2 - TRB1_SUB_LOG\n" 
								retrieveTRXSub;;
								3) echo "\n3 - TRB1_SUB_ERRS\n" 
								retrieveTRXErrs;;
								4) echo "\n4 - TRB1MANAGER\n" 
								trb1manager;;
								5) echo "\n4 - TLS API INVOKER 1\n" 
								tlsinvoker1;;
								6) echo "\n4 - CL API INVOKER\n" 
								clinvoker;;
								7) echo "\n4 - TLS API INVOKER 10\n" 
								tlsinvoker10;;
								8) echo "\n4 - BL BTLSOR\n" 
								btlsor;;
								9) echo "\n4 - TC UH Rating\n" 
								uhrating;;
								10) echo "\n4 - TC UH Guiding\n" 
								uhguiding;;
								11) echo "\n4 - ADJ1CYCMN\n" 
								adj1cycmn;;
								99) echo "$(tput bold)\nBye - Have a nice day!\n" 
								Menu=99;;
								esac

        done
}

############function for TRX_PUB_LOG############
retrieveTRXPub () {
				
				submenu=0
				
        while [[ $submenu -ne 1 ]] do
								echo "=============================================================="
                echo ""
                echo "$(tput bold)$(tput sgr0)- Please insert the Customer ID (Or press ENTER to search without a Customer ID)"
                echo ""
                read CBP_ID?'- Enter Customer ID: '
        
        if [[ $CBP_ID == "" ]]; then
        
					PUB_Result=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
					set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
					SELECT COUNT(*) FROM TRB1_PUB_LOG WHERE ENTITY_TYPE LIKE '%CUSTOMER%' AND ENTITY_ID='$CBP_ID';
					exit;
					END`
					
					if [[ $PUB_Result -lt 1 ]]; then
		       		echo "\nNo entries without a customer in TRB1_PUB_LOG table\n"
					 		echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 		read menu
					 		submenu=1
					 		main_menu
					 		
					else
					
					 pub=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
					 SELECT SOURCE_COMP_ID, PUB_TRX_ID, ENTITY_TYPE, ENTITY_ID FROM TRB1_PUB_LOG WHERE ENTITY_TYPE LIKE '%CUSTOMER%' AND ENTITY_ID=$CBP_ID;
		       exit;
		       END`
		     
		     	 echo "$pub\n";
		     	 echo "$(tput setaf 2)PRESS ENTER TO RAISE RELEVANT DAEMONS/JOBS$(tput sgr0)"
		     	 read menu
		     	 trb1manager
		       submenu=1
		       
		      fi 

        else
        
        CBP_Result=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
				set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
				SELECT COUNT(*) FROM CUSTOMER WHERE CUSTOMER_ID='$CBP_ID';
				exit;
				END`

				if [[ $CBP_Result -lt 1 ]]; then
				   echo "\nCustomer ID not found in ABP database\n"
					 echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 read menu
					 submenu=1
					 main_menu
					 
				else
				
					PUB_Result=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
					set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
					SELECT COUNT(*) FROM TRB1_PUB_LOG WHERE ENTITY_TYPE LIKE '%CUSTOMER%' AND ENTITY_ID='$CBP_ID';
					exit;
					END`
					
					if [[ $PUB_Result -lt 1 ]]; then
		       		echo "\nNo entries for this customer in TRB1_PUB_LOG table\n"
					 		echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 		read menu
					 		submenu=1
					 		main_menu
					 		
					else
					
					 pub=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
					 SELECT SOURCE_COMP_ID, PUB_TRX_ID, ENTITY_TYPE, ENTITY_ID FROM TRB1_PUB_LOG WHERE ENTITY_TYPE LIKE '%CUSTOMER%' AND ENTITY_ID=$CBP_ID;
		       exit;
		       END`
		     	 
		     	 echo "$pub\n";
		     	 echo "$(tput bold)$(tput sgr0) Would you like to execute relevant Daemons/Jobs?"
		     	 echo "$(tput bold)[1] $(tput sgr0) - YES"
		     	 echo "$(tput bold)[2] $(tput sgr0) - NO"
		     	 read menu
		     	 
		     	 if [[ $menu -ne 1 ]]; then
		       	echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 	read menu
		       	submenu=1
		       else
		       	trb1manager
		       	echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 	read menu
		       	submenu=1
		       fi   		       
					fi
				fi
			fi  
    done
}
############function for TRX_PUB_LOG############


############function for TRX_SUB_LOG############
retrieveTRXSub () {
				
				submenu=0
				
        while [[ $submenu -ne 1 ]] do
								echo "=============================================================="
                echo ""
                echo "$(tput bold)$(tput sgr0)- Please insert the Customer ID (Or press ENTER to search without a Customer ID)"
                echo ""
                read CBP_ID?'- Enter Customer ID: '
               
        if [[ $CBP_ID == "" ]]; then
        
					SUB_Result=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
					set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
					SELECT COUNT(*) FROM TRB1_SUB_LOG WHERE ENTITY_ID IS NULL;
					exit;
					END`
					
					if [[ $SUB_Result -lt 1 ]]; then
		       		echo "\nNo entries without a customer in TRB1_SUB_LOG table\n"
					 		echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 		read menu
					 		submenu=1
					 		main_menu
					 		
					else
					
					 sub=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
					 SELECT RPAD(TSUB.SUB_APPL_ID,6) APP_ID, RPAD(TSUB.SUB_TRX_ID,6) TRX_ID, RPAD(TSUB.ENTITY_TYPE,11) ENTITY_TYPE, RPAD(TSUB.ENTITY_ID,10) ENTITY_ID, RPAD(TMEM.MEMBER_ID,10) MEMBER_ID, RPAD(TMEM.MEMBER_CODE,11) MEMBER_CODE, RPAD(TMEM.MEMBER_DESC,48) MEMBER_DESC FROM TRB1_SUB_LOG TSUB JOIN TRB1_MEMBERS TMEM ON TSUB.SUB_APPL_ID=TMEM.MEMBER_ID WHERE TSUB.ENTITY_ID IS NULL AND TMEM.MEMBER_IS_ACTIVE='Y';
		       exit;
		       END`
		     
		     	 echo "$sub\n";
		     	 echo "$(tput setaf 2)PRESS ENTER TO RAISE RELEVANT DAEMONS/JOBS$(tput sgr0)"
		     	 read menu
		     	 trb1manager
		       submenu=1
		       
		      fi 

        else
        
        CBP_Result=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
				set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
				SELECT COUNT(*) FROM CUSTOMER WHERE CUSTOMER_ID='$CBP_ID';
				exit;
				END`
				
				if [[ $CBP_Result -lt 1 ]]; then
				   echo "\nCustomer ID not found in ABP database\n"
					 echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 read menu
					 submenu=1
					 main_menu
					 
				else
				
					SUB_Result=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
					set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
					SELECT COUNT(*) FROM TRB1_SUB_LOG WHERE ENTITY_TYPE LIKE '%CUSTOMER%' AND ENTITY_ID='$CBP_ID';
					exit;
					END`
					
					if [[ $SUB_Result -lt 1 ]]; then
		       		echo "\nNo entries for this customer in TRB1_SUB_LOG table\n"
					 		echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 		read menu
					 		submenu=1
					 		main_menu
					 		
					else
					
					 sub=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
					 SELECT RPAD(TSUB.SUB_APPL_ID,6) APP_ID, RPAD(TSUB.SUB_TRX_ID,6) TRX_ID, RPAD(TSUB.ENTITY_TYPE,11) ENTITY_TYPE, RPAD(TSUB.ENTITY_ID,10) ENTITY_ID, RPAD(TMEM.MEMBER_ID,10) MEMBER_ID, RPAD(TMEM.MEMBER_CODE,11) MEMBER_CODE, RPAD(TMEM.MEMBER_DESC,48) MEMBER_DESC FROM TRB1_SUB_LOG TSUB JOIN TRB1_MEMBERS TMEM ON TSUB.SUB_APPL_ID=TMEM.MEMBER_ID WHERE TSUB.ENTITY_TYPE LIKE '%CUSTOMER%' AND TSUB.ENTITY_ID=$CBP_ID AND TMEM.MEMBER_IS_ACTIVE='Y';
		       exit;
		       END`
		     
		     	 echo "$sub\n";
		     	 echo "$(tput bold)$(tput sgr0) Would you like to execute relevant Daemons/Jobs?"
		     	 echo "$(tput bold)[1] $(tput sgr0) - YES"
		     	 echo "$(tput bold)[2] $(tput sgr0) - NO"
		     	 read menu
		     	 
		     	 if [[ $menu -ne 1 ]]; then
		       	echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 	read menu
		       	submenu=1
		       else
		       	raisedaemon
		       	echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 	read menu
		       	submenu=1
		       fi	
					fi
				fi
			fi 
     done
}
############function for TRX_SUB_LOG############


############function for TRX_SUB_ERRS############
retrieveTRXErrs () {
				
				submenu=0
				
        while [[ $submenu -ne 1 ]] do
								echo "=============================================================="
                echo ""
                echo "$(tput bold)$(tput sgr0)- Please insert the Customer ID (Or press ENTER to search without a Customer ID)"
                echo ""
                read CBP_ID?'- Enter Customer ID: '
        
          if [[ $CBP_ID == "" ]]; then
        
					ERRS_Result=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
					set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
					SELECT COUNT(*) FROM TRB1_SUB_ERRS WHERE ENTITY_ID IS NULL;
					exit;
					END`
					
					if [[ $ERRS_Result -lt 1 ]]; then
		       		echo "\nNo entries without a customer in TRB1_PUB_ERRS table\n"
					 		echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 		read menu
					 		submenu=1
					 		main_menu
					 		
					else
					
						errs=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
						set linesize 4000 wrap off trimout on
						SELECT RPAD(TERRS.SUB_APPL_ID,6) APP_ID, RPAD(TERRS.SUB_TRX_ID,6) TRX_ID, RPAD(TERRS.APPLICATION_CODE,8) APP_CODE, RPAD(TERRS.ERROR_CODE,16) ERROR_CODE, RPAD(TERRS.ERROR_ISSUE_DATE,14) ERR_ISSUE_DATE, RPAD(TERRS.ENTITY_TYPE,11) ENTITY_TYPE, RPAD(TERRS.ENTITY_ID,10) ENTITY_ID, RPAD(TMEM.MEMBER_ID,10) MEMBER_ID, RPAD(TMEM.MEMBER_CODE,11) MEMBER_CODE, RPAD(TMEM.MEMBER_DESC,48) MEMBER_DESC FROM TRB1_SUB_ERRS TERRS JOIN TRB1_MEMBERS TMEM ON TERRS.SUB_APPL_ID=TMEM.MEMBER_ID WHERE TERRS.ENTITY_ID IS NULL;
						exit;
						END`
		     
		     	 echo "$errs\n";
		       echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 read menu
		       submenu=1
		       
		      fi 

        else
        
        CBP_Result=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
				set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
				SELECT COUNT(*) FROM CUSTOMER WHERE CUSTOMER_ID='$CBP_ID';
				exit;
				END`
				
			  if [[ $CBP_Result -lt 1 ]]; then
				   echo "\nCustomer ID not found in ABP database\n"
					 echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 read menu
					 submenu=1
					 main_menu
					 
				else
				
					ERRS_Result=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
					set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
					SELECT COUNT(*) FROM TRB1_SUB_ERRS WHERE ENTITY_TYPE LIKE '%CUSTOMER%' AND ENTITY_ID='$CBP_ID';
					exit;
					END`
					
					if [[ $ERRS_Result -lt 1 ]]; then
		       		echo "\nNo entries for this customer in TRB1_SUB_ERRS table\n"
					 		echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 		read menu
					 		submenu=1
					 		main_menu
					 		
					else
					
					  errs=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
						set linesize 4000 wrap off trimout on
						SELECT RPAD(TERRS.SUB_APPL_ID,6) APP_ID, RPAD(TERRS.SUB_TRX_ID,6) TRX_ID, RPAD(TERRS.APPLICATION_CODE,8) APP_CODE, RPAD(TERRS.ERROR_CODE,16) ERROR_CODE, RPAD(TERRS.ERROR_ISSUE_DATE,14) ERR_ISSUE_DATE, RPAD(TERRS.ENTITY_TYPE,11) ENTITY_TYPE, RPAD(TERRS.ENTITY_ID,10) ENTITY_ID, RPAD(TMEM.MEMBER_ID,10) MEMBER_ID, RPAD(TMEM.MEMBER_CODE,11) MEMBER_CODE, RPAD(TMEM.MEMBER_DESC,48) MEMBER_DESC FROM TRB1_SUB_ERRS TERRS JOIN TRB1_MEMBERS TMEM ON TERRS.SUB_APPL_ID=TMEM.MEMBER_ID WHERE TERRS.ENTITY_TYPE LIKE '%CUSTOMER%' AND TERRS.ENTITY_ID=$CBP_ID;
						exit;
						END`

		     	 echo "$errs\n";
		       echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
					 read menu
		       submenu=1
		       
				 fi
			 fi
		fi  
   done
}
############function for TRX_SUB_ERRS############

############function for TRB1Manager############
trb1manager () {
		clear
		tmenu=0
		
		while [[ $tmenu -ne 9 ]] do

								checkjob=`ps -fu $USER | grep TRB1Manager |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
                echo ""
                #Checks for TRB1MANAGER
								if [[ $checkjob -ne 1 ]]; then
      						echo "=========================================================="
      						echo " TRB1Manager is \033[41m DOWN \033[0m, please check the reason"
      						echo "=========================================================="
 								else
      						echo "=================="
      						echo " TRB1Manager $(tput setaf 2) UP $(tput sgr0)"
      						echo "=================="
								fi
								#Checks for TRB1MANAGER
                echo ""
                echo "$(tput bold)$(tput setaf 1)Please remember to exit the menu to execute other daemons/jobs$(tput sgr0)"
                echo "Choose an option:"
                echo ""
                echo "$(tput bold)[1] $(tput sgr0)- START TRB1MANAGER"
                echo "$(tput bold)[2] $(tput sgr0)- RESTART TRB1MANAGER"
                echo "$(tput bold)[3] $(tput sgr0)- STOP TRB1MANAGER"
                echo "$(tput bold)$(tput setaf 1)[9] $(tput bold)$(tput setaf 1)- Return to Main Menu$(tput sgr0)"
                echo ""
                read tmenu?'Chosen Option: '

                case $tmenu in
								1) echo "\n1 - START TRB1MANAGER\n" 
									checkjob=`ps -fu $USER | grep TRB1Manager |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 1 ]]; then
										echo "\nTRB1MANAGER already $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
									echo "TRB1MANAGER is \033[41m DOWN \033[0m. $(tput setaf 2)PRESS ENTER TO RAISE TRB1MANAGER...$(tput sgr0)"
									read menu
									TRB1RunManager_Sh -e 1 -r PR
									while [[ $checkjob -ne 1 ]] do
										checkjob=`ps -fu $USER | grep TRB1Manager |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
										sleep 5s
									done
										echo "\nTRB1MANAGER is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;	
								2) echo "\n2 - RESTART TRB1MANAGER\n"
									checkjob=`ps -fu $USER | grep TRB1Manager |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nTRB1MANAGER is \033[41m DOWN \033[0m. Starting TRB1MANAGER. Please wait...\n"
										sleep 1s
										TRB1RunManager_Sh -e 1 -r PR
										while [[ $checkjob -ne 1 ]] do
											checkjob=`ps -fu $USER | grep TRB1Manager |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTRB1MANAGER is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nTRB1MANAGER is $(tput setaf 2)UP$(tput sgr0). Stopping TRB1MANAGER. Please wait...\n"
										TRB1StopManager_Sh -m
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep TRB1Manager |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTRB1MANAGER is \033[41m DOWN \033[0m\n"
										echo "$(tput setaf 2)PRESS ENTER TO RAISE TRB1MANAGER...$(tput sgr0)"
										read menu
										TRB1RunManager_Sh -e 1 -r PR
										while [[ checkjob -eq 0 ]] do
												checkjob=`ps -fu $USER | grep TRB1Manager |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTRB1MANAGER is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								3) echo "\n3 - STOP TRB1MANAGER\n"
									checkjob=`ps -fu $USER | grep TRB1Manager |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nTRB1MANAGER is already \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nTRB1MANAGER is $(tput setaf 2)UP$(tput sgr0). Stopping TRB1MANAGER. Please wait...\n"
										TRB1StopManager_Sh -m
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep TRB1Manager |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTRB1MANAGER is \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								9) echo "$(tput bold)\nReturning!\n" 
								tmenu=9;;
								esac
   done
}  
############function for TRB1Manager############

############function for TLS API Invoker1############
tlsinvoker1 () {
		clear
		tmenu=0
		
		while [[ $tmenu -ne 9 ]] do

								checkjob=`ps -fu $USER | grep TLS1_APInvoker_1_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
                echo ""
                #Checks for TLS1APINV_1
								if [ $checkjob -ne 1 ]
 								then
      						echo "=========================================================="
      						echo " TLS1APINV_1 is \033[41m DOWN \033[0m, please check the reason"
      						echo "=========================================================="
 								else
      						echo "=================="
      						echo " TLS1APINV_1 $(tput setaf 2) UP $(tput sgr0)"
      						echo "=================="
								fi
								#Checks for TLS1APINV_1
                echo ""
                echo "$(tput bold)$(tput setaf 1)Please remember to exit the menu to execute other daemons/jobs$(tput sgr0)"
                echo "Choose an option:"
                echo ""
                echo "$(tput bold)[1] $(tput sgr0)- START TLS API Invoker 1"
                echo "$(tput bold)[2] $(tput sgr0)- RESTART TLS API Invoker 1"
                echo "$(tput bold)[3] $(tput sgr0)- STOP TLS API Invoker 1"
                echo "$(tput bold)$(tput setaf 1)[9] $(tput bold)$(tput setaf 1)- Return to Main Menu$(tput sgr0)"
                echo ""
                read tmenu?'Chosen Option: '

                case $tmenu in
								1) echo "\n1 - START TLS API Invoker 1\n" 
									checkjob=`ps -fu $USER | grep TLS1_APInvoker_1_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 1 ]]; then
										echo "\nTLS API Invoker 1 already $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
									echo "TLS API Invoker 1 is \033[41m DOWN \033[0m. $(tput setaf 2)PRESS ENTER TO RAISE TLS API Invoker 1...$(tput sgr0)"
									read menu
									TLS1RunAPInvoker_Sh -n 1 -r 1
									while [[ $checkjob -ne 1 ]] do
										checkjob=`ps -fu $USER | grep TLS1_APInvoker_1_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
										sleep 5s
									done
										echo "\nTLS API Invoker 1 is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;	
								2) echo "\n2 - RESTART TLS API Invoker 1\n"
									checkjob=`ps -fu $USER | grep TLS1_APInvoker_1_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\TLS API Invoker 1 is \033[41m DOWN \033[0m. Starting TLS API Invoker 1. Please wait...\n"
										sleep 1s
										TLS1RunAPInvoker_Sh -n 1 -r 1
										while [[ $checkjob -ne 1 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_1_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTLS API Invoker 1 is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nTLS API Invoker 1 is $(tput setaf 2)UP$(tput sgr0). Stopping TLS API Invoker 1. Please wait...\n"
										TLS1StopAPInvoker_Sh -n 1 -r 1
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_1_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTLS API Invoker 1 is \033[41m DOWN \033[0m\n"
										echo "$(tput setaf 2)PRESS ENTER TO RAISE TLS API Invoker 1...$(tput sgr0)"
										read menu
										TLS1RunAPInvoker_Sh -n 1 -r 1
										while [[ checkjob -eq 0 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_1_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTLS API Invoker 1 is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								3) echo "\n3 - STOP TLS API Invoker 1\n"
									checkjob=`ps -fu $USER | grep TLS1_APInvoker_1_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nTLS API Invoker 1 is already \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nTLS API Invoker 1 is $(tput setaf 2)UP$(tput sgr0). Stopping TLS API Invoker 1. Please wait...\n"
										TLS1StopAPInvoker_Sh -n 1 -r 1
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_1_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTLS API Invoker 1 is \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								9) echo "$(tput bold)\nReturning!\n" 
								tmenu=9;;
								esac
   done
}  
############function for TLS API Invoker1############

############function for CL API Invoker############
clinvoker () {
		clear
		tmenu=0
		
		while [[ $tmenu -ne 9 ]] do

								checkjob=`ps -fu $USER | grep TLS1_APInvoker_2_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
                echo ""
                #Checks for TLS1APINV_2
								if [ $checkjob -ne 1 ]
 								then
      						echo "=========================================================="
      						echo " TLS1APINV_2 is \033[41m DOWN \033[0m, please check the reason"
      						echo "=========================================================="
 								else
      						echo "=================="
      						echo " TLS1APINV_2 $(tput setaf 2) UP $(tput sgr0)"
      						echo "=================="
								fi
								#Checks for TLS1APINV_2
                echo ""
                echo "$(tput bold)$(tput setaf 1)Please remember to exit the menu to execute other daemons/jobs$(tput sgr0)"
                echo "Choose an option:"
                echo ""
                echo "$(tput bold)[1] $(tput sgr0)- START CL API Invoker"
                echo "$(tput bold)[2] $(tput sgr0)- RESTART CL API Invoker"
                echo "$(tput bold)[3] $(tput sgr0)- STOP CL API Invoker"
                echo "$(tput bold)$(tput setaf 1)[9] $(tput bold)$(tput setaf 1)- Return to Main Menu$(tput sgr0)"
                echo ""
                read tmenu?'Chosen Option: '

                case $tmenu in
								1) echo "\n1 - START CL API Invoker\n" 
									checkjob=`ps -fu $USER | grep TLS1_APInvoker_2_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 1 ]]; then
										echo "\nCL API Invoker already $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
									echo "CL API Invoker is \033[41m DOWN \033[0m. $(tput setaf 2)PRESS ENTER TO RAISE CL API Invoker...$(tput sgr0)"
									read menu
									TLS1RunAPInvoker_Sh -n 2 -r 1
									while [[ $checkjob -ne 1 ]] do
										checkjob=`ps -fu $USER | grep TLS1_APInvoker_2_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
										sleep 5s
									done
										echo "\nCL API Invoker is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;	
								2) echo "\n2 - RESTART CL API Invoker\n"
									checkjob=`ps -fu $USER | grep TLS1_APInvoker_2_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\CL API Invoker is \033[41m DOWN \033[0m. Starting CL API Invoker. Please wait...\n"
										sleep 1s
										TLS1RunAPInvoker_Sh -n 2 -r 1
										while [[ $checkjob -ne 1 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_2_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nCL API Invoker is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nCL API Invoker is $(tput setaf 2)UP$(tput sgr0). Stopping CL API Invoker. Please wait...\n"
										TLS1StopAPInvoker_Sh -n 2 -r 1
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_2_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nCL API Invoker is \033[41m DOWN \033[0m\n"
										echo "$(tput setaf 2)PRESS ENTER TO RAISE CL API Invoker...$(tput sgr0)"
										read menu
										TLS1RunAPInvoker_Sh -n 2 -r 1
										while [[ checkjob -eq 0 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_2_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nCL API Invoker is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								3) echo "\n3 - STOP CL API Invoker\n"
									checkjob=`ps -fu $USER | grep TLS1_APInvoker_2_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nCL API Invoker is already \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nCL API Invoker is $(tput setaf 2)UP$(tput sgr0). Stopping CL API Invoker. Please wait...\n"
										TLS1StopAPInvoker_Sh -n 2 -r 1
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_2_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nCL API Invoker is \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								9) echo "$(tput bold)\nReturning!\n" 
								tmenu=9;;
								esac
   done
}  
############function for CL API Invoker############

############function for TLS API Invoker10############
tlsinvoker10 () {
		clear
		tmenu=0
		
		while [[ $tmenu -ne 9 ]] do

								checkjob=`ps -fu $USER | grep TLS1_APInvoker_10_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
                echo ""
                #Checks for TLS1APINV_10
								if [ $checkjob -ne 1 ]
 								then
      						echo "=========================================================="
      						echo " TLS1APINV_10 is \033[41m DOWN \033[0m, please check the reason"
      						echo "=========================================================="
 								else
      						echo "=================="
      						echo " TLS1APINV_10 $(tput setaf 2) UP $(tput sgr0)"
      						echo "=================="
								fi
								#Checks for TLS1APINV_10
                echo ""
                echo "$(tput bold)$(tput setaf 1)Please remember to exit the menu to execute other daemons/jobs$(tput sgr0)"
                echo "Choose an option:"
                echo ""
                echo "$(tput bold)[1] $(tput sgr0)- START TLS API Invoker 10"
                echo "$(tput bold)[2] $(tput sgr0)- RESTART TLS API Invoker 10"
                echo "$(tput bold)[3] $(tput sgr0)- STOP TLS API Invoker 10"
                echo "$(tput bold)$(tput setaf 1)[9] $(tput bold)$(tput setaf 1)- Return to Main Menu$(tput sgr0)"
                echo ""
                read tmenu?'Chosen Option: '

                case $tmenu in
								1) echo "\n1 - START TLS API Invoker 10\n" 
									checkjob=`ps -fu $USER | grep TLS1_APInvoker_10_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 1 ]]; then
										echo "\nTLS API Invoker 10 already $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
									echo "TLS API Invoker 10 is \033[41m DOWN \033[0m. $(tput setaf 2)PRESS ENTER TO RAISE TLS API Invoker 10...$(tput sgr0)"
									read menu
									TLS1RunAPInvoker_Sh -n 10 -r 1
									while [[ $checkjob -ne 1 ]] do
										checkjob=`ps -fu $USER | grep TLS1_APInvoker_10_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
										sleep 5s
									done
										echo "\nTLS API Invoker 10 is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;	
								2) echo "\n2 - RESTART TLS API Invoker 10\n"
									checkjob=`ps -fu $USER | grep TLS1_APInvoker_10_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\TLS API Invoker 10 is \033[41m DOWN \033[0m. Starting TLS API Invoker 10. Please wait...\n"
										sleep 1s
										TLS1RunAPInvoker_Sh -n 10 -r 1
										while [[ $checkjob -ne 1 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_10_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTLS API Invoker 10 is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nTLS API Invoker 10 is $(tput setaf 2)UP$(tput sgr0). Stopping TLS API Invoker 10. Please wait...\n"
										TLS1StopAPInvoker_Sh -n 10 -r 1
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_10_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTLS API Invoker 10 is \033[41m DOWN \033[0m\n"
										echo "$(tput setaf 2)PRESS ENTER TO RAISE TLS API Invoker 1...$(tput sgr0)"
										read menu
										TLS1RunAPInvoker_Sh -n 10 -r 1
										while [[ checkjob -eq 0 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_10_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTLS API Invoker 10 is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								3) echo "\n3 - STOP TLS API Invoker 10\n"
									checkjob=`ps -fu $USER | grep TLS1_APInvoker_10_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nTLS API Invoker 10 is already \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nTLS API Invoker 10 is $(tput setaf 2)UP$(tput sgr0). Stopping TLS API Invoker 10. Please wait...\n"
										TLS1StopAPInvoker_Sh -n 10 -r 1
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep TLS1_APInvoker_10_1 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTLS API Invoker 10 is \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								9) echo "$(tput bold)\nReturning!\n" 
								tmenu=9;;
								esac
   done
}  
############function for TLS API Invoker10############

############function for BL BTLSOR############
btlsor () {
		clear
		tmenu=0
		
		while [[ $tmenu -ne 9 ]] do

								checkjob=`ps -fu $USER | grep BL1BTLSOR |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
                echo ""
                #Checks for BL1BTLSOR
								if [ $checkjob -ne 1 ]
 								then
      						echo "=========================================================="
      						echo " BL BTLSOR is \033[41m DOWN \033[0m, please check the reason"
      						echo "=========================================================="
 								else
      						echo "=================="
      						echo " BL BTLSOR $(tput setaf 2) UP $(tput sgr0)"
      						echo "=================="
								fi
								#Checks for BL1BTLSOR
                echo ""
                echo "$(tput bold)$(tput setaf 1)Please remember to exit the menu to execute other daemons/jobs$(tput sgr0)"
                echo "Choose an option:"
                echo ""
                echo "$(tput bold)[1] $(tput sgr0)- START BL BTLSOR"
                echo "$(tput bold)[2] $(tput sgr0)- RESTART BL BTLSOR"
                echo "$(tput bold)[3] $(tput sgr0)- STOP BL BTLSOR"
                echo "$(tput bold)$(tput setaf 1)[9] $(tput bold)$(tput setaf 1)- Return to Main Menu$(tput sgr0)"
                echo ""
                read tmenu?'Chosen Option: '

                case $tmenu in
								1) echo "\n1 - START BL BTLSOR\n" 
									checkjob=`ps -fu $USER | grep BL1BTLSOR |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 1 ]]; then
										echo "\nBL BTLSOR already $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
									echo "BL BTLSOR is \033[41m DOWN \033[0m. $(tput setaf 2)PRESS ENTER TO RAISE BL BTLSOR...$(tput sgr0)"
									read menu
									export AMC_API_USE=N
									bl1_runproc_Ksh bl1BTLServer -n BL1BTLSOR -f REGULAR
									while [[ $checkjob -ne 1 ]] do
										checkjob=`ps -fu $USER | grep BL1BTLSOR |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
										sleep 5s
									done
										echo "\nBL BTLSOR is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;	
								2) echo "\n2 - RESTART BL BTLSOR\n"
									checkjob=`ps -fu $USER | grep BL1BTLSOR |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nBL BTLSOR is \033[41m DOWN \033[0m\n. Starting BL BTLSOR. Please wait...\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
										export AMC_API_USE=N
										bl1_runproc_Ksh bl1BTLServer -n BL1BTLSOR -f REGULAR
										while [[ $checkjob -ne 1 ]] do
											checkjob=`ps -fu $USER | grep BL1BTLSOR |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nBL BTLSOR is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nBL BTLSOR is $(tput setaf 2)UP$(tput sgr0). Stopping BL BTLSOR. Please wait...\n"
										export AMC_API_USE=N
										bl1_killproc_Ksh $USER 'bl1BTLServer -n BL1BTLSOR -f REGULAR'
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep BL1BTLSOR |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nBL BTLSOR is \033[41m DOWN \033[0m\n"
										echo "$(tput setaf 2)PRESS ENTER TO RAISE BL BTLSOR...$(tput sgr0)"
										read menu
										export AMC_API_USE=N
										bl1_runproc_Ksh bl1BTLServer -n BL1BTLSOR -f REGULAR
										while [[ checkjob -eq 0 ]] do
												checkjob=`ps -fu $USER | grep BL1BTLSOR |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nBL BTLSOR is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								3) echo "\n3 - STOP BL BTLSOR\n"
									checkjob=`ps -fu $USER | grep BL1BTLSOR |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nBL BTLSOR is already \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nBL BTLSOR is $(tput setaf 2)UP$(tput sgr0). Stopping BL BTLSOR. Please wait...\n"
										export AMC_API_USE=N
										bl1_killproc_Ksh $USER 'bl1BTLServer -n BL1BTLSOR -f REGULAR'
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep BL1BTLSOR |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nBL BTLSOR is \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								9) echo "$(tput bold)\nReturning!\n" 
								tmenu=9;;
								esac
   done
}  
############function for BL BTLSOR############

############function for TC UH Rating############
uhrating () {
		clear
		tmenu=0
		
		while [[ $tmenu -ne 9 ]] do

								checkjob=`ps -fu $USER | grep UHI_RT547 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
                echo ""
                #Checks for TC UH Rating
								if [ $checkjob -ne 1 ]
 								then
      						echo "=========================================================="
      						echo " TC UH Rating is \033[41m DOWN \033[0m, please check the reason"
      						echo "=========================================================="
 								else
      						echo "=================="
      						echo " TC UH Rating $(tput setaf 2) UP $(tput sgr0)"
      						echo "=================="
								fi
								#Checks for TC UH Rating
                echo ""
                echo "$(tput bold)$(tput setaf 1)Please remember to exit the menu to execute other daemons/jobs$(tput sgr0)"
                echo "Choose an option:"
                echo ""
                echo "$(tput bold)[1] $(tput sgr0)- START TC UH Rating"
                echo "$(tput bold)[2] $(tput sgr0)- RESTART TC UH Rating"
                echo "$(tput bold)[3] $(tput sgr0)- STOP TC UH Rating"
                echo "$(tput bold)$(tput setaf 1)[9] $(tput bold)$(tput setaf 1)- Return to Main Menu$(tput sgr0)"
                echo ""
                read tmenu?'Chosen Option: '

                case $tmenu in
								1) echo "\n1 - START TC UH Rating\n" 
									 checkjob=`ps -fu $USER | grep UHI_RT547 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 1 ]]; then
										echo "\nTC UH Rating already $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
									echo "TC UH Rating is \033[41m DOWN \033[0m. $(tput setaf 2)PRESS ENTER TO RAISE TC UH Rating...$(tput sgr0)"
									read menu
									export AMC_API_USE=N
									ADJ1_UH_Job_Shell_Sh -n UHI_RT547 -c "-profileFile UH3_ImpleIncModeRating -runningMode FORCE_START "
									while [[ $checkjob -ne 1 ]] do
										checkjob=`ps -fu $USER | grep UHI_RT547 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
										sleep 5s
									done
										echo "\nTC UH Rating is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;	
								2) echo "\n2 - RESTART TC UH Rating\n"
									 checkjob=`ps -fu $USER | grep UHI_RT547 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nTC UH Rating is \033[41m DOWN \033[0m\n. Starting TC UH Rating. Please wait...\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
										export AMC_API_USE=N
										ADJ1_UH_Job_Shell_Sh -n UHI_RT547 -c "-profileFile UH3_ImpleIncModeRating -runningMode FORCE_START "
										while [[ $checkjob -ne 1 ]] do
											checkjob=`ps -fu $USER | grep UHI_RT547 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTC UH Rating is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nTC UH Rating is $(tput setaf 2)UP$(tput sgr0). Stopping TC UH Rating. Please wait...\n"
										uh=pgrep -f UHI_RT547
										kill -15 $uh
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep UHI_RT547 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTC UH Rating is \033[41m DOWN \033[0m\n"
										echo "$(tput setaf 2)PRESS ENTER TO RAISE TC UH Rating...$(tput sgr0)"
										read menu
										export AMC_API_USE=N
										ADJ1_UH_Job_Shell_Sh -n UHI_RT547 -c "-profileFile UH3_ImpleIncModeRating -runningMode FORCE_START "
										while [[ checkjob -eq 0 ]] do
											checkjob=`ps -fu $USER | grep UHI_RT547 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTC UH Rating is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								3) echo "\n3 - STOP TC UH Rating\n"
									checkjob=`ps -fu $USER | grep UHI_RT547 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nTC UH Rating is already \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nTC UH Rating is $(tput setaf 2)UP$(tput sgr0). Stopping TC UH Rating. Please wait...\n"
										uh=pgrep -f UHI_RT547
										kill -15 $uh
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep UHI_RT547 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTC UH Rating is \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								9) echo "$(tput bold)\nReturning!\n" 
								tmenu=9;;
								esac
   done
}  
############function for TC UH Rating############

############function for TC UH Guiding############
uhguiding () {
		clear
		tmenu=0
		
		while [[ $tmenu -ne 9 ]] do

								checkjob=`ps -fu $USER | grep UHI_GD537 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
                echo ""
                #Checks for TC UH Guiding
								if [ $checkjob -ne 1 ]
 								then
      						echo "=========================================================="
      						echo " TC UH Guiding is \033[41m DOWN \033[0m, please check the reason"
      						echo "=========================================================="
 								else
      						echo "=================="
      						echo " TC UH Guiding $(tput setaf 2) UP $(tput sgr0)"
      						echo "=================="
								fi
								#Checks for TC UH Guiding
                echo ""
                echo "$(tput bold)$(tput setaf 1)Please remember to exit the menu to execute other daemons/jobs$(tput sgr0)"
                echo "Choose an option:"
                echo ""
                echo "$(tput bold)[1] $(tput sgr0)- START TC UH Guiding"
                echo "$(tput bold)[2] $(tput sgr0)- RESTART TC UH Guiding"
                echo "$(tput bold)[3] $(tput sgr0)- STOP TC UH Guiding"
                echo "$(tput bold)$(tput setaf 1)[9] $(tput bold)$(tput setaf 1)- Return to Main Menu$(tput sgr0)"
                echo ""
                read tmenu?'Chosen Option: '

                case $tmenu in
								1) echo "\n1 - START TC UH Guiding\n" 
									 checkjob=`ps -fu $USER | grep UHI_GD537 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 1 ]]; then
										echo "\nTC UH Guiding already $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
									echo "TC UH Guiding is \033[41m DOWN \033[0m. $(tput setaf 2)PRESS ENTER TO RAISE TC UH Guiding...$(tput sgr0)"
									read menu
									export AMC_API_USE=N
									ADJ1_UH_Job_Shell_Sh -n UHI_GD537 -c "-profileFile UHImpleIncModeGuiding -runningMode NORMAL "
									while [[ $checkjob -ne 1 ]] do
										checkjob=`ps -fu $USER | grep UHI_GD537 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
										sleep 5s
									done
										echo "\nTC UH Guiding is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;	
								2) echo "\n2 - RESTART TC UH Guiding\n"
									 checkjob=`ps -fu $USER | grep UHI_GD537 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nTC UH Guiding is \033[41m DOWN \033[0m\n. Starting TC UH Guiding. Please wait...\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
										export AMC_API_USE=N
										ADJ1_UH_Job_Shell_Sh -n UHI_GD537 -c "-profileFile UHImpleIncModeGuiding -runningMode NORMAL "
										while [[ $checkjob -ne 1 ]] do
											checkjob=`ps -fu $USER | grep UHI_GD537 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTC UH Guiding is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nTC UH Guiding is $(tput setaf 2)UP$(tput sgr0). Stopping TC UH Guiding. Please wait...\n"
										uh=pgrep -f UHI_GD537
										kill -15 $uh
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep UHI_GD537 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTC UH Guiding is \033[41m DOWN \033[0m\n"
										echo "$(tput setaf 2)PRESS ENTER TO RAISE TC UH Guiding...$(tput sgr0)"
										read menu
										export AMC_API_USE=N
										ADJ1_UH_Job_Shell_Sh -n UHI_GD537 -c "-profileFile UHImpleIncModeGuiding -runningMode NORMAL "
										while [[ checkjob -eq 0 ]] do
											checkjob=`ps -fu $USER | grep UHI_GD537 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTC UH Guiding is $(tput setaf 2)UP$(tput sgr0)\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								3) echo "\n3 - STOP TC UH Guiding\n"
									checkjob=`ps -fu $USER | grep UHI_GD537 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
									if [[ checkjob -eq 0 ]]; then
										echo "\nTC UH Guiding is already \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									else
										echo "\nTC UH Guiding is $(tput setaf 2)UP$(tput sgr0). Stopping TC UH Guiding. Please wait...\n"
										uh=pgrep -f UHI_GD537
										kill -15 $uh
										while [[ checkjob -eq 1 ]] do
											checkjob=`ps -fu $USER | grep UHI_GD537 |grep -v grep |grep -v tail |grep -v less |grep -v more |wc -l`
											sleep 5s
										done
										echo "\nTC UH Guiding is \033[41m DOWN \033[0m\n\n"
										echo "$(tput setaf 2)PRESS ENTER TO RETURN TO MENU$(tput sgr0)"
										read menu
										clear
									fi;;
								9) echo "$(tput bold)\nReturning!\n" 
								tmenu=9;;
								esac
   done
}  
############function for TC UH Guiding############

############function for ADJ1CYCMNTEOD############
adj1cycmn () {
	
		tmenu=0
		
		while [[ $tmenu -ne 9 ]] do
		
								echo "========================================="
                echo ""
                echo ""
                echo "$(tput bold)$(tput sgr0)Run ADJ1CYCMNTEOD ENDDAY?"
                echo "$(tput bold)$(tput setaf 1)[1]$(tput sgr0) - YES$(tput sgr0)"
                echo "$(tput bold)$(tput setaf 1)[2]$(tput sgr0) - NO$(tput sgr0)"
                echo ""
                read tmenu?'Chosen Option: '
    
    case $tmenu in
    	1) echo "\nRunning ADJ1CYCMNTEOD. Please wait until job finishes..."
    		 RunJobs ADJ1CYCMNTEOD ENDDAY -b >/dev/null 2>&1
    		 sleep 5s
    		 echo "\n$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"	
				 read menu
				 tmenu=9;;
    	2) echo "$(tput bold)\nExiting...\n" 
				 echo "\n$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"	
				 read menu
				 tmenu=9;;
    esac		
    done
}		
############function for ADJ1CYCMNTEOD############

##############function RaiseDaemon##############
raisedaemon () {
	
	rmenu=0
			
				counter=`sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
				set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
				SELECT COUNT(DISTINCT MEMBER_ID) FROM TRB1_MEMBERS JOIN TRB1_SUB_LOG ON SUB_APPL_ID=MEMBER_ID WHERE ENTITY_TYPE LIKE '%CUSTOMER%' AND ENTITY_ID=$CBP_ID;
		    exit;
		    END`
	
				set -A arrayRaise `sqlplus -s ${APP_DB_USER}/${APP_DB_PASS}@${APP_DB_INST} <<END
				set feedback off termout off echo off verify off heading off pages 0 trims on trimspool On
				SELECT DISTINCT MEMBER_ID FROM TRB1_MEMBERS JOIN TRB1_SUB_LOG ON SUB_APPL_ID=MEMBER_ID WHERE ENTITY_TYPE LIKE '%CUSTOMER%' AND ENTITY_ID=$CBP_ID;
		    exit;
		    END`
				
				echo "=============================================================="
        echo ""
        echo "$(tput bold)$(tput sgr0)- Raise Daemon Function"
        echo ""
        echo "=============================================================="

				for((i=0;i<$counter;i++)); do
				
				case ${arrayRaise[i]} in
				#TLS API Invoker1
				3000) tlsinvoker1;;
				3006)	tlsinvoker1;;
				3007) tlsinvoker1;;
				3012) tlsinvoker1;;
				3049) tlsinvoker1;;
				#TLS API Invoker1
				
				#BL BTLSOR
				3008)	btlsor;;
				#BL BTLSOR
				
				#CL API Invoker
				3009) clinvoker;;
				#CL API Invoker
								
				#TLS API Invoker10
				3014) tlsinvoker10;;
				#TLS API Invoker10
				
				#TC UH Rating
				3015) uhrating;;
				#TC UH Rating
				
				#TC UH Guiding
				3016) uhguiding;;
				#TC UH Guiding
				
				#Cycle Maintenance Job
				3017) adj1cycmn;;
				#Cycle Maintenance Job
				
				#TRB1 Adapter
				3091) echo "TRB1 Adapter is responsible for this Transaction."
							echo "\nTBR1 Adapter is also raised automatically when raising TRB1 Manager. Please check if TRB1 Manager is up and/or restart it.\n"
							echo "$(tput setaf 2)PRESS ENTER TO CONTINUE$(tput sgr0)"
							read menu
							trb1manager;;
				#TRB1 Adapter
				
				esac
				
				done
}

##############function RaiseDaemon##############

main_menu