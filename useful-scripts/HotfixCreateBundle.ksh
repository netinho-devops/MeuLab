#!/bin/ksh
#===============================================================
# NAME      :  HotfixCreateBundle.ksh
# Programmer:  Pedro Pavan
# Date      :  15-Apr-14
# Purpose   :  Create HF bundle from a HF list 
#              with automatic checks
#
# Changes history:
#
#  Date     |    By       | Changes/New features
# ----------+-------------+-------------------------------------
# 04-15-14    Pedro Pavan   Initial version
# 04-30-14    Pedro Pavan   Accept HF from other verios (-v 0)
# 05-30-14    Pedro Pavan   Friendly verbose message
#===============================================================

#=========================================
# Usage: HotfixCreateBundle.ksh [-v <number>] [-f <file>] [-e <R|G>] [-h] [-d]
#
# HotfixCreateBundle.ksh -v 3500 -f REFRESH_ST53_3500_405.hf -e G -d
#
# -v   Version number
#
# -f   HF file list (one HF id per line)
#
# -e   Execute mode (R to RUN and G to GENERATE)
#
# -d   Debug mode
#
# -h   Display help
#
#=========================================


######################################
# HF Tool DB
######################################
Get_Genesis_DB() {
    
    case "$HOST" in
        "stllin80")
            GENESIS_DB="intamc/intamc@ATMABP"
            ;;

        "snelnx195")
            GENESIS_DB="intamc/intamc@FOMSUAT1"
            ;;
    
                  *)
            echo "Unknown host, please connect to stllin80 or snelnx195."
            exit 1
            ;;
    esac

    echo ${GENESIS_DB}
}

######################################
# Temporary files
######################################
TMP_FILE_MANUAL_HF_LIST="manual_hf_list.txt"
TMP_FILE_HF_VERSION_LIST="version_hf_list.txt"
TMP_FILE_1_HF_SORTED_LIST="step1_sorted_hf_list.txt"
TMP_FILE_2_HF_SORTED_LIST="step2_sorted_hf_list.txt"
TMP_FILE_3_HF_SORTED_LIST="step3_sorted_hf_list.txt"
HF_DEPLOY_LIST_TXT="HF_LIST.txt"
HF_DEPLOY_LIST_SQL="HF_LIST.sql"

######################################
# Variables
######################################
MSG_LENGHT=40

######################################
# Usage
######################################
Usage() {
    EXIT_CODE=$1

    echo ""
    echo "Usage: $(basename $0) [-v <number>] [-f <folder>] [-e <R|G>] [-h] [-d]"
    echo ""
    echo "  -v   Version number		(set 0 to ignore versions)			"
    echo ""
    echo "  -f   HF file 			(HF list with one HF id per line)	"
    echo ""
    echo "  -e   Execute mode 		(R to RUN and G to GENERATE)		"
    echo ""
    echo "  -d   Debug mode												"
    echo ""
    echo "  -h   Display help                                         	"
    echo ""

    exit ${EXIT_CODE}
}

######################################
# Display verbose message
######################################
Message() {
    if [ ${DEBUG} == "Y" ]; then
        MSG=$@
        MAX=$(expr ${MSG_LENGHT} - 1)
        INDEX=$(echo ${#MSG})        

        for i in {${INDEX}..${MAX}}
        do
            MSG=$MSG" "
        done
        
        echo -en "\n\E[35m[DEBUG]\E[0m ${MSG}"
    fi
}

######################################
# Progress message
######################################
Progress() {
    if [ ${DEBUG} == "Y" ]; then
        echo -ne "\033[50G"
        STEP[0]="       "
        STEP[1]="...    "
        STEP[2]="ERROR  "
        STEP[3]="DONE   "

        sleep 0.5

        case "$1" in
            "--loading")
                echo -e "\E[34m${STEP[1]}\E[0m" "\c"
            ;;

            "--end")
                if [ $? -eq 0 ]; then
                    echo -e "\E[32m${STEP[3]}\E[0m" "\c"
                else
                    echo -e "\E[31m${STEP[2]}\E[0m" "\c"
                fi
            ;;

            *)
                echo -e ${STEP[0]} "\c"
            ;;
        esac
    fi
}

######################################
# Fetch HF list info 
######################################
Fetch_HFs_Info() {
    TARGET_FILE=$1
    SQL_HF_LIST=$(cat $TARGET_FILE | tr '\n' ',')
    BUNDLE_CSV="$(echo ${TARGET_FILE%.*}).csv"

    Message "Fetching data & Gathering statistics"
    Progress --loading

    echo -e "HOTFIX ID,PRODUCT,VERSION,CREATION DATE,REJECTED,APPROVED,MANUAL STEP,AUTO DEPLOY,CONTACT,STATUS,COMMENTS" > ${BUNDLE_CSV}
    print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500

        SELECT M.UNIQUE_ID AS HF_ID,
        M.PRODUCT AS PRODUCT,
        M.RELEASE AS VERSION,
        TO_CHAR(M.CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS HF_CREATION,
        DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_EVT WHERE UNIQUE_ID = M.UNIQUE_ID AND EVENT_NAME = 'REJECTED'),
              0,'NO',
              1,'YES',
              'YES') AS REJECTED,
        DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_EVT WHERE UNIQUE_ID = M.UNIQUE_ID AND EVENT_NAME = 'APPROVED'),
              0,'NO',
              1,'YES',
              'YES') AS APPROVED,
        DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = M.UNIQUE_ID AND UNIQUE_ID IN (SELECT UNIQUE_ID FROM HOTFIX_AP_RELATIONS 
                                                                                                         WHERE UNIQUE_ID = M.UNIQUE_ID 
                                                                                                           AND PARAM_ID = 1 
                                                                                                           AND PARAM_VALUE = 'YES')),
              0, 'NO',
              1, 'YES',
              'YES') AS MANUAL_STEP,
        DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = M.UNIQUE_ID AND UNIQUE_ID NOT IN (SELECT UNIQUE_ID FROM HOTFIX_AUTO_DEPLOY)),
              0, 'YES',
              1, 'NO',
              'NO') AS AUTO_DEPLOY,
        M.CREATED_BY AS CONTACT_PERSON
        FROM HOTFIX_MNG M
        WHERE M.UNIQUE_ID IN ("${SQL_HF_LIST%?}")
        ORDER BY M.UNIQUE_ID ASC;    
        " | sqlplus -S $HF_DB_CONN | awk '{ print $1","$2","$3","$4" "$5","$6","$7","$8","$9","$10 }' >> ${BUNDLE_CSV}
        
        Statistics ${BUNDLE_CSV}

        Progress --end
}

######################################
# Bundle Statistics
######################################
Statistics() {
    TARGET_FILE=$1
    
    OMS_COUNT=$(grep -i 'oms' ${TARGET_FILE} | wc -l)
    CRM_COUNT=$(grep -i 'crm' ${TARGET_FILE} | wc -l)
    ABP_COUNT=$(grep -i 'abp' ${TARGET_FILE} | wc -l)
    ALL_COUNT=$(($OMS_COUNT+$CRM_COUNT+$ABP_COUNT)) 

    VERSION_COUNT=$(cut -d',' -f3 ${TARGET_FILE} | grep -v 'VERSION' | grep -v ${VERSION} | wc -l)
    REJECTED_COUNT=$(cut -d',' -f5 ${TARGET_FILE} | grep -v 'REJECTED' | grep -i 'yes' | wc -l)
    APPROVED_COUNT=$(cut -d',' -f7 ${TARGET_FILE} | grep -v 'APPROVED' | grep -i 'no' | wc -l)
    MANUAL_COUNT=$(cut -d',' -f8 ${TARGET_FILE} | grep -v 'AUTO DEPLOY' | grep -i 'no' | wc -l)

    print "\nOMS,CRM,ABP,TOTAL\n${OMS_COUNT},${CRM_COUNT},${ABP_COUNT},${ALL_COUNT}\nWRONG VERSION,REJECTED,NON APPROVED,MANUAL DEPLOY\n${VERSION_COUNT},${REJECTED_COUNT},${APPROVED_COUNT},${MANUAL_COUNT}" >> ${TARGET_FILE}
}

######################################
# Sort and remove duplicated HFs
######################################
Arrange_List() {
    TARGET_FILE=$1
    SORTED_LIST=$2

    Message "Sorting list & Remove duplicated HFs"
    Progress --loading

    cat ${TARGET_FILE} | sort | uniq > ${SORTED_LIST}

    Progress --end
}

######################################
# Detecting HF (with manual steps)
######################################
Detect_Manual_Step() {
    CURRENT_VERSION=$1
    OUTPUT_FILE=$2

    Message "Detecting HF (looking for manual steps)"
    Progress --loading

    print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SELECT UNIQUE_ID 
        FROM HOTFIX_MNG 
        WHERE RELEASE = "${CURRENT_VERSION}" 
        AND UNIQUE_ID NOT IN (SELECT UNIQUE_ID FROM HOTFIX_AUTO_DEPLOY) 
        ORDER BY UNIQUE_ID;" |   
     sqlplus -S $HF_DB_CONN  |
                 sed '/^$/d' |
           sed 's/^[ \t]*//' > ${OUTPUT_FILE}

    Progress --end
}

######################################
# Detecting HF (with wrong version)
######################################
Detect_Wrong_Version() {
    TARGET_LIST=$1
    OUTPUT_FILE=$2

    touch $OUTPUT_FILE

    if [ ${VERSION} -eq 0 ]; then
        Message "Detecting HF (accepting all versions)"
        Progress --loading
        Progress --end
        return
    fi

    Message "Detecting HF (looking for wrong version)"
    Progress --loading
    
    for HF_ID in $(cat ${TARGET_LIST})
    do
        IS_SAME_VERSION=$(print "
            WHENEVER SQLERROR EXIT 5
            SET FEEDBACK OFF
            SET HEADING OFF
            SET PAGES 0
            SELECT COUNT(*) FROM HOTFIX_MNG WHERE UNIQUE_ID = "$HF_ID" AND RELEASE = "$VERSION";" | sqlplus -S $HF_DB_CONN)

        [ $IS_SAME_VERSION -eq 0 ] && echo $HF_ID >> ${OUTPUT_FILE}
    done

    Progress --end
}

######################################
# Generate HF list
######################################
Generate_List() {
    FILE_1=$1
    FILE_2=$2
    FILE_3=$3

    FILE_MANUAL=$4
    FILE_VERSION=$5

    OUTPUT_FILE=$6

    Message "Performing changes to generate HF list"
    Progress --loading

    comm -23 ${FILE_1} ${FILE_MANUAL} > ${FILE_2}
    comm -23 ${FILE_2} ${FILE_VERSION} > ${FILE_3}
    cp ${FILE_3} ${OUTPUT_FILE}

    Progress --end
}

######################################
# Check if specific HF is approved
######################################
Check_Approved() {
    HF_ID=$1
 
    APPROVED=$(print "
    WHENEVER SQLERROR EXIT 5
    SET FEEDBACK OFF
    SET HEADING OFF
    SET PAGES 0
    SELECT COUNT(*) FROM HOTFIX_EVT WHERE UNIQUE_ID = "${HF_ID}" AND EVENT_NAME = 'APPROVED';" | sqlplus -S $HF_DB_CONN)

    if [ ${APPROVED} -eq 0 ]
    then
        echo "N"
    else
        echo "Y"
    fi
}

######################################
# Approve HF list
######################################
Approve_List() {
    LIST=$1
    
    Message "Approving entire HF list"
    Progress --loading
    
    for HF_ID in $(cat ${LIST})
    do
        STATUS=$(Check_Approved ${HF_ID}) 

        [[ ${STATUS} == "N" ]] && print " INSERT INTO HOTFIX_EVT (UNIQUE_ID, EVENT_NAME , FILE_NAME, ENVIRONMENT, CREATION_DATE, DEPLOY_TYPE, LAST_MODIFIED_BY) 
                                          VALUES ("${HF_ID}", 'APPROVED', 'N/A', 'N/A', SYSDATE, 'Ready', 'pedrop');
                                          commit;" | sqlplus -S $HF_DB_CONN > /dev/null 2>&1
    done

    Progress --end
}

######################################
# Create HF Bundle
######################################
Create_Bundle() {
    HF_LIST=$1
    INPUT_FILE=$2

	BUNDLE_FILE=$(echo ${INPUT_FILE%.*})
    BUNDLE_NAME="$(echo ${INPUT_FILE%.*})_$(date +'%Y%m%d')"
    BUNDLE_DESC="Created "$(date '+%d-%b-%Y %H-%M-%S')
    HF_SEQUENCE=1

    Message "Creating HF Bundle (SQL file)"
    Progress --loading
    Remove_File ${BUNDLE_FILE}.sql
    
    for HF_ID in $(cat ${HF_LIST})
    do
        echo "INSERT INTO HOTFIX_BUNDLES (BUNDLE_NAME, BUNDLE_DESC, UNIQUE_ID, ORDER_NUM, SYS_CREATION_DATE, APPLICATION_ID) VALUES ('${BUNDLE_NAME}', '${BUNDLE_DESC}', ${HF_ID}, ${HF_SEQUENCE}, SYSDATE, 'HF');" >> ${BUNDLE_FILE}.sql
        HF_SEQUENCE=$(expr $HF_SEQUENCE + 1)
    done

    echo "commit;" >> ${BUNDLE_FILE}.sql

    Progress --end
}

######################################
# Remove file
######################################
Remove_File() {
    TARGET_FILE=$1

    [ -f ${TARGET_FILE} ] && rm -f ${TARGET_FILE}
}

######################################
# Remove temp files
######################################
Clean_Tmp_Files() {

    Message "Removing temporary files"
    Progress --loading

    Remove_File $TMP_FILE_MANUAL_HF_LIST
    Remove_File $TMP_FILE_HF_VERSION_LIST
    Remove_File $TMP_FILE_1_HF_SORTED_LIST
    Remove_File $TMP_FILE_2_HF_SORTED_LIST
    Remove_File $TMP_FILE_3_HF_SORTED_LIST
    Remove_File $HF_DEPLOY_LIST_TXT
    
    Progress --end
}

######################################
# Check Folder and files
######################################
Check_Folder_Files() {
	BUNDLE_FILE=$1
    BUNDLE_DIR=$(dirname $0)
	BUNDLE_NAME=$(echo ${1%.*})
	BUNDLE_FOLDER="${BUNDLE_NAME}_$(date +'%Y%m%d')"
	
	cd ${BUNDLE_DIR}
	[ ! -d ./${BUNDLE_FOLDER} ] && mkdir ${BUNDLE_FOLDER}
	mv -f ${BUNDLE_FILE} ${BUNDLE_FOLDER}/
	cd ${BUNDLE_FOLDER}/
}

######################################
# Check Bundle on DB
######################################
Check_Bundle() {
    BUNDLE_NAME=$(echo ${1%.*})

    BUNDLE_COUNT=$(print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500

        SELECT COUNT(*) FROM HOTFIX_BUNDLES WHERE BUNDLE_NAME = '${BUNDLE_NAME}';
    " | sqlplus -S $HF_DB_CONN | sed 's/^[ \t]*//')

    if [ ${BUNDLE_COUNT} -eq 0 ]; then
        echo "N"
    else
		echo "Y"
	fi
}

######################################
# Send email
######################################
Send_Email() {
    BUNDLE_FOLDER=$1
    
	SUBJECT="Bundle | $(/bin/date '+%Y/%m/%d') | $(basename $0) $*"
	BODY=$(echo "Bundle has been created, please find files attached.")
	TO="pedroa@amdocs.com"
	
    cat ${SQL_FILE} | sqlplus -S $HF_DB_CONN
}

######################################
# Execute SQL file
######################################
Execute_SQL() {
    SQL_FILE=$1
    
    cat ${SQL_FILE} | sqlplus -S $HF_DB_CONN
}

######################################
# Main
######################################
DEBUG="N"

cd ~/utility_scripts/hotfix/bundle/

while getopts ":hdv:f:e:" opt
do 
    case "${opt}" in
        h)  
            Usage 0
            ;;
    
        d)
            DEBUG="Y"
            ;;
        v)
            VERSION=${OPTARG}
            ;;
        f)
            FILE=${OPTARG}
            ;;
        e)
            EXEC_MODE=${OPTARG}
            ;;
        *)
            Usage 1
            ;;
    esac 
done

shift $(($OPTIND -1))

if [ -z ${VERSION} ] || [ -z ${FILE} ] || [ -z ${EXEC_MODE} ]
then
    Usage 2
fi

if [ ${EXEC_MODE} != "R" ] && [ ${EXEC_MODE} != "G" ]
then
    Usage 3
fi

HF_DB_CONN=$(Get_Genesis_DB)

Check_Folder_Files ${FILE}

echo "============================================================"
echo " Start time $(/bin/date '+%Y-%m-%d %H:%M:%S')               "
echo "============================================================"

Fetch_HFs_Info ${FILE}

Arrange_List ${FILE} ${TMP_FILE_1_HF_SORTED_LIST}

Detect_Manual_Step ${VERSION} ${TMP_FILE_MANUAL_HF_LIST} 

Detect_Wrong_Version ${TMP_FILE_1_HF_SORTED_LIST} ${TMP_FILE_HF_VERSION_LIST}

Generate_List ${TMP_FILE_1_HF_SORTED_LIST} ${TMP_FILE_2_HF_SORTED_LIST} ${TMP_FILE_3_HF_SORTED_LIST} ${TMP_FILE_MANUAL_HF_LIST} ${TMP_FILE_HF_VERSION_LIST} ${HF_DEPLOY_LIST_TXT}

Approve_List ${HF_DEPLOY_LIST_TXT}

Create_Bundle ${HF_DEPLOY_LIST_TXT} ${FILE} ${HF_DEPLOY_LIST_SQL}

if [[ ${EXEC_MODE} == "R" ]]
then
	Progress --loading
	
    if [ $(Check_Bundle ${FILE}) == "N" ]; then
		Message "Creating bundle on DB"
		Execute_SQL ${HF_DEPLOY_LIST_SQL}
	else
		Message "Bundle already exists!!!"
	fi
   
    Progress --end
fi

Clean_Tmp_Files

Message "Bundle Terminated, check files in $(pwd)\n"

echo ""
echo "============================================================"
echo " Finish time $(/bin/date '+%Y-%m-%d %H:%M:%S')              "
echo "============================================================"
