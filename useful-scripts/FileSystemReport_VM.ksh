#!/bin/ksh
#MENU_DESCRIPTION=Provide detailed report of FS usage (VM)
#===============================================================
# NAME      :  EnvironmentFilesystemReport.ksh
# Programmer:  Pedro Pavan
# Date      :  20-Jan-14
# Purpose   :  Provide detailed report of FS usage
#
# Changes history:
#
#  Date     |     By        | Changes/New features
# ----------+---------------+-------------------------------------
# 01-20-14	  Pedro Pavan     	Initial version
# 08-28-14    Pedro Pavan		Send email
# 10-22-14    Pedro Pavan		New HTML layout
# 12-09-14    Pedro Pavan		Accepting parameters
# 05-04-15    Pedro Pavan		UAT
# 04-19-16    Pedro Pavan		VMs
#===============================================================

##############################################
# PARAMETERS
##############################################
EMAIL_LIST="pedroa@amdocs.com,duilioa@amdocs.com"
TARGET_FS="/dev/mapper/vg01-users"
TARGET_USER="vivtools"
HTMLFILE="filesystem_vm.html"

######################################
# Usage
######################################
Usage() {
    EXIT_CODE=$1

    echo ""
    echo "Usage: $(basename $0) -r <report_type> -a <alert_level> [-h]		  "
    echo ""
    echo "  -r   Output report type:								  		  "			
	echo "       	- HTML: 	Generate html file for report page		      "
	echo "       	- PDF: 		Generate PDF file  						      "
    echo ""
    echo "  -a   File system usage (%) to send alert mail				   	  "
	echo ""
    echo "  -s   Silent mode                                         		  "
    echo ""
    echo "  -h   Display help                                         		  "	
    echo ""

    exit ${EXIT_CODE}
}

######################################
# Display message
######################################
Message() {
	MSG=$*
	
	[ "${IS_SILENT}" == "N" ] && echo -e "${MSG}"
}

##############################################
# Create HTML file
##############################################
html_create_file()
{
	FILE=$1
    echo -e "<html xmlns=\"http://www.w3.org/1999/xhtml\">" > ${FILE}
}

##############################################
# Create HTML head
##############################################
html_head()
{
	FILE=$1
    echo -e "
    <head>
		<meta http-equiv=\"refresh\" content=\"60\">
        <title>Filesystem Report</title>
    </head>" >> ${FILE}
}

##############################################
# Create HTML body
##############################################
html_body()
{
	FILE=$1
    echo -e "
    <body>

    <style type=\"text/css\"> 
            body, p { font-family: verdana,arial,helvetica; font-size: 95%; color:#000000; }

            th { font-family: verdana,arial,helvetica; color:#FFFFFF; background:#000099; font-size: 100%; border:1px solid #3399FF; padding:3px 7px 2px 7px; }
            
            td { font-family: verdana,arial,helvetica; color:#000000; background:#eeeee0; font-size:1em; border:1px solid #3399FF; padding:3px 7px 2px 7px; } 
            
            .critical { background: #FF0033; text-align:center; }
            .warning { background: #FFFF33; text-align:center; }
            .normal { background: #99FF33; text-align:center; }
    </style>    
        
        <p>Last update $(date '+%d-%b-%Y %H:%M:%S')</p>" >> ${FILE}
}

##############################################
# Close HTML tags
##############################################
html_end()
{
	FILE=$1
    echo -e "
    </body>
</html>" >> ${FILE}
}

##############################################
# Deploy HTML file
##############################################
html_deploy()
{
    FILE=$1
	HOSTNAME=$(hostname)
	
	if [ "${IS_REPORT}" == "Y" ]; then
	
		APACHE_PATH="${HOME}/Amc-${HOSTNAME}/tomcat/webapps/amc_${HOSTNAME}/reports"

		case "${REPORT_TYPE}" in
			"HTML")
				if [ -d ${APACHE_PATH} ]; then
				    rm -f ${APACHE_PATH}/${FILE}
					cp ${FILE} ${APACHE_PATH}/
					echo -e "\n[DONE] HTML report was generated - ${APACHE_PATH}/${FILE}"
				fi
			;;
			
			"PDF")
				PDF_FILE="$(echo ${FILE%.*}).pdf"
				~/utility_scripts/BIN/utils_html2pdf -q ${FILE} ${PDF_FILE}
				mv -f ${PDF_FILE} ${HOME}/${PDF_FILE}
				echo -e "\n[DONE] PDF report was generated - ${HOME}/${PDF_FILE}"
			;;
		esac
	fi

	rm ${FILE}
}

##############################################
# Get HTML from UAT
##############################################
html_uat() {
        echo "null"
}

##############################################
# Get color based on use percent
##############################################
color_use() {
	USE=$1
	TYPE=$2
	COLOR=""
	
	case ${TYPE} in
		"output")
			COLOR_YELLOW="\033[33m"
			COLOR_GREEN="\033[32m"
			COLOR_RED="\033[31m"
			COLOR_END="\033[0m"

			case ${USE} in
				[0-9]|[1-6][0-9]|70) COLOR="${COLOR_GREEN}${USE}${COLOR_END}"	;; # 0-70
					  7[1-9]|8[0-9]) COLOR="${COLOR_YELLOW}${USE}${COLOR_END}"	;; # 71-89
						 9[0-9]|100) COLOR="${COLOR_RED}${USE}${COLOR_END}"		;; # 90-100
								  *) COLOR=""									;; 
			esac
		;;
	
		"html")
			case ${USE} in
				[0-9]|[1-6][0-9]|70) COLOR="class=\"normal\""	;; # 0-70
					  7[1-9]|8[0-9]) COLOR="class=\"warning\""	;; # 71-89
						 9[0-9]|100) COLOR="class=\"critical\""	;; # 90-100
								  *) COLOR=""					;; 
			esac
		;;
		
		*)
			echo "${USE}"
		;;
	esac
	
	echo ${COLOR}
}

##############################################
# Create filesystem table 
##############################################
html_table_fs()
{
	TMP_FILE="/tmp/fs_report.txt"
	HOST_FILE="/tmp/host_report.txt"
	HTML_FILE=$1
	HEADER="   "
	BG_COLOR_BLUE="\033[44m"
	COLOR_MAGENTA="\033[35m"
	COLOR_END="\033[0m"
	
	echo "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500

		select distinct HOST from GNS_VM_PROD_STATUS where VM_PROD_STATUS = 'ACTIVE';
	" | sqlplus -S ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE} > ${HOST_FILE}

#	for machine in $(cat ${HOST_FILE}); do
	for machine in $(cat ${HOST_FILE} | head -n 3); do
		ssh ${TARGET_USER}@${machine} 'df -h' | grep -v 'dvcinas' | awk '{ print $5";"$1 }' | grep -v '^Use' | sort -rn | head -10 | sed 's/%//g' > ${TMP_FILE}

		SEND_ALERT_MAIL="N"
		PERCENT=0
		MACHINE_DETAILS=$(cat work/vm_creation.sql | sed "s/%VM%/${machine}/g" | sqlplus -S ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE})
		MACHINE_EXPIRATION=$(cat work/vm_expiration.sql | sed "s/%VM%/${machine}/g" | sqlplus -S ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE} | sed '/^$/d')
		MACHINE_OWNER="$(echo ${MACHINE_DETAILS} | cut -d ',' -f 1)"
		MACHINE_CREATION="$(echo ${MACHINE_DETAILS} | cut -d ',' -f 2)"

		if [[ "${MACHINE_DETAILS}" == *"ORA-"* ]]; then
			MACHINE_DETAILS="NA,NA"
		fi

		if [[ "${MACHINE_EXPIRATION}" == *"ORA-"* ]]; then
			MACHINE_EXPIRATION="NA"
		fi

		Message "\n${BG_COLOR_BLUE}${HEADER}${machine}${HEADER}${COLOR_END}"
		Message "${COLOR_MAGENTA}USE(%)\tFILESYSTEM${COLOR_END}"
		Message "${COLOR_MAGENTA}---------------------------------------------------------------------------------------------------------------------${COLOR_END}"

		echo -e "
			<br>
			<hr>
			<h1 id=\"$machine\">Machine: $machine</h1>
			<ul style=\"list-style-type:disc\">
				<li><b>Owner:</b> ${MACHINE_OWNER}</li>
				<li><b>Creation:</b> ${MACHINE_CREATION}</li>
				<li><b>Expiration:</b> ${MACHINE_EXPIRATION}</li>
			</ul>  
			<br>
	   
			<table border=\"1\">
					<tr>
						<th>FileSystem</th>
						<th>Use (%)</th>
					</tr>" >> ${HTML_FILE}
	
		for line in $(cat ${TMP_FILE}); do
				
			FS=$(echo "$line" | cut -d ';' -f 2)
			USE=$(echo "$line" | cut -d ';' -f 1)
			
			# Alert
			if [ "${IS_ALERT}" = "Y" ]; then
				if [ "${FS}" == "${TARGET_FS}" ]; then
					if [ ${USE} -ge ${ALERT_LEVEL} ]; then
						SEND_ALERT_MAIL="Y"
						PERCENT=${USE}
					fi
				fi
			fi
			
			# STDOUT
			Message "$(color_use ${USE} output)\t${FS}"
			
			# HTML
			echo -e "    
                <tr>
                    <td>${FS}</td>
                    <td $(color_use $USE html)>${USE}</td>
                </tr>" >> ${HTML_FILE}
			
		done
		
		Message "\n> Owner: ${MACHINE_OWNER}\n> Created: ${MACHINE_CREATION}\n> Expiration: ${MACHINE_EXPIRATION}"
		echo -e "
			</table><br>" >> ${HTML_FILE}

		if [ "${SEND_ALERT_MAIL}" == "Y" ]; then
			mkdir ./work/ 2> /dev/null
			MAILFILE="./work/filesystem_${machine}.txt"

			echo -e "From: vivtools@indlin3362.amdocs.com\nTo: ${MACHINE_OWNER}@amdocs.com\nCc: ${EMAIL_LIST}\nSubject: [VIVO] File system report - VM#${machine}\n" > ${MAILFILE}
			echo -e "Hi, ${MACHINE_OWNER}.\n" >> ${MAILFILE}
			echo -e "This is an automatic e-mail to alert you about File System (${PERCENT}%) in your VM.\nPlease see status below:\n" >> ${MAILFILE}
			ssh ${TARGET_USER}@${machine} 'cd /users/gen/ ; du -s * 2>&-| sort -rn | cut -f2 | xargs du -sh 2>&-' | egrep 'abp|crm|oms|ams|asm|omn|wsf|slr' >> ${MAILFILE}
			#cat work/cleanup_instructions.new >> ${MAILFILE}
			echo -e "\nFor more information please access following URL:\nhttp://indlin3662:5000/amc_indlin3662/reports/filesystem_vm.html#${machine}" >> ${MAILFILE}
			echo -e "\n\nRegards,\nVIVO Infra Team" >> ${MAILFILE}
		fi
		rm ${TMP_FILE}
	done
}

send_email()
{
	COUNT=0
	cd work/
	for email in $(ls -1 *indlnqw* 2> /dev/null); do
       	#cat ${email} | /usr/lib/sendmail -t
		#echo ${email}
		sleep 1
        #rm ${email}
		COUNT=$(expr ${COUNT} + 1)
    done
	
	echo -e "[DONE] Total of sent e-mails: ${COUNT}"
}

##############################################
# Main
##############################################
IS_SILENT="N"
IS_REPORT="N"
IS_ALERT="N"
SEND_ALERT_MAIL="N"

cd ${HOME}/Scripts/filesystem/VM/
rm work/filesystem_indlnqw* 2> /dev/null
clear

while getopts ":hsua:r:" opt
do 
	case "${opt}" in
		h)  
			Usage 0
			;;
		a)
			IS_ALERT="Y"
			ALERT_LEVEL=${OPTARG}
			;;
		r)
			IS_REPORT="Y"
			REPORT_TYPE=$(echo ${OPTARG} | tr [a-z] [A-Z])
			;;
		s)
			IS_SILENT="Y"
			;;
		u)
			html_uat
			;;
		*)
			Usage 1
			;;
	esac 
done

if [ "${IS_ALERT}" = "Y" ]; then
	if [ ${ALERT_LEVEL} -lt 1 ] || [ ${ALERT_LEVEL} -gt 100 ]; then
		Usage 1
	fi	
fi

if [ "${IS_REPORT}" = "Y" ]; then
	if [ "${REPORT_TYPE}" != "HTML" ] && [ "${REPORT_TYPE}" != "PDF" ]; then
		Usage 1
	fi
fi

html_create_file $HTMLFILE
html_head $HTMLFILE
html_body $HTMLFILE
html_table_fs $HTMLFILE
html_end $HTMLFILE
html_deploy $HTMLFILE

send_email

#rm ${HOST_FILE}
exit 0
