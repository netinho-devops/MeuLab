#!/bin/ksh
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
#===============================================================

##############################################
# PARAMETERS
##############################################
EMAIL_LIST="pedroa@amdocs.com,duilioa@amdocs.com"
TARGET_HOSTS="indlin3555,indlin3401,indlin3402,indlin3403"
TARGET_USER="vivtools"
TARGET_FS_NAME="vivuser"
TARGET_MARKET="viv"

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
					echo -e "[DONE] HTML report was generated - ${APACHE_PATH}/${FILE}"
				fi
			;;
			
			"PDF")
				PDF_FILE="$(echo ${FILE%.*}).pdf"
				~/utility_scripts/BIN/utils_html2pdf -q ${FILE} ${PDF_FILE}
				mv -f ${PDF_FILE} ${HOME}/${PDF_FILE}
				echo -e "[DONE] PDF report was generated - ${HOME}/${PDF_FILE}"
			;;
		esac
	fi
	
	if [ "${SEND_ALERT_MAIL}" == "Y" ]; then
        #mailx -s "$(echo -e "[DELIVERY] File system report - ALERT!!!\nContent-Type: text/html")" "${EMAIL_LIST}" < ${FILE} > /dev/null 2>&1
		echo "http://indlin3662:5000/amc_indlin3662/reports/filesystem.html" | mailx -s "[VIVO] File system report" "${EMAIL_LIST}" > /dev/null 2>&1
		echo -e "[DONE] Alert e-mail was sent (ST) - ${EMAIL_LIST}"
	fi

	rm ${FILE}
}

##############################################
# Get HTML from UAT
##############################################
html_uat() {
        #scp ensight@snelnx195:~/Amc-snelnx195/tomcat/webapps/amc_snelnx195/reports/filesystem.html filesystem_uat.html > /dev/null 2>&1
        #UAT_ALERT=$(grep "<td class" filesystem_uat.html | egrep -q 'critical|warning' ; echo $?)
        #UAT_ALERT=$(grep "<td class" filesystem_uat.html | egrep -q 'critical' ; echo $?)
        echo "TODO"
        #if [ ${UAT_ALERT} -eq 0 ]; then
        #    mailx -s "$(echo -e "[UAT] File system report - ALERT!!!\nContent-Type: text/html")" "${EMAIL_LIST}" < filesystem_uat.html > /dev/null 2>&1
        #    echo -e "[DONE] Alert e-mail was sent (UAT) - ${EMAIL_LIST}"
        #fi
		#
        #rm filesystem_uat.html
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
	HTML_FILE=$1
	
	HEADER="   "
	BG_COLOR_BLUE="\033[44m"
	COLOR_MAGENTA="\033[35m"
	COLOR_END="\033[0m"
	
	for machine in $(echo ${TARGET_HOSTS} | tr ',' '\n'); do
		ssh ${TARGET_USER}@${machine} 'df -h' | grep "/${TARGET_FS_NAME}" | awk '{ print $6":"$5":"$4 }' | sort -n > ${TMP_FILE}
		Message "\n${BG_COLOR_BLUE}${HEADER}${machine}${HEADER}${COLOR_END}"
		Message "${COLOR_MAGENTA}FILESYSTEM \t AVAILABLE \t USE(%) \t USERS${COLOR_END}"
		Message "${COLOR_MAGENTA}---------------------------------------------------------------------------------------------------------------------${COLOR_END}"
	
		echo -e "
			<br>
			<h1>Machine: $machine</h1>
			<hr>
			<br>
	   
			<table border=\"1\">
					<tr>
						<th>FileSystem</th>
						<th>Available</th>
						<th>Use (%)</th>
						<th>Users</th>
					</tr>" >> ${HTML_FILE}
	
		for filesystem in $(cat ${TMP_FILE}); do
				
			FS=$(echo "$filesystem" | cut -d ':' -f 1)
			USE=$(echo "$filesystem" | cut -d ':' -f 2 | sed 's/%//g')
			AVAIL=$(echo "$filesystem" | cut -d ':' -f 3)
			USERS=$(ssh ${TARGET_USER}@${machine} 'cat /etc/passwd' | grep "${FS}" | egrep "^${TARGET_MARKET}" | cut -d ':' -f 1 | tr '\n' ',' | sed 's/,$//' | sort -n)
			
			# Alert
			if [ "${IS_ALERT}" = "Y" ]; then
				[ ${USE} -ge ${ALERT_LEVEL} ] && SEND_ALERT_MAIL="Y"
			fi
			
			# STDOUT
			Message "${FS} \t ${AVAIL} \t\t $(color_use ${USE} output) \t\t ${USERS}"
			
			# HTML
			echo -e "    
                <tr>
                    <td>${FS}</td>
                    <td>${AVAIL}</td>
                    <td $(color_use $USE html)>${USE}</td>
                    <td>${USERS}</td>
                </tr>" >> ${HTML_FILE}
			
		done
		
		echo -e "
			</table><br>" >> ${HTML_FILE}
		
		rm ${TMP_FILE}
	done
}

##############################################
# Main
##############################################
IS_SILENT="N"
IS_REPORT="N"
IS_ALERT="N"
SEND_ALERT_MAIL="N"

cd ${HOME}/Scripts/filesystem/

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

HTMLFILE="filesystem.html"

html_create_file $HTMLFILE
html_head $HTMLFILE
html_body $HTMLFILE
html_table_fs $HTMLFILE
html_end $HTMLFILE
html_deploy $HTMLFILE

exit 0
