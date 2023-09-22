#!/bin/ksh
#MENU_DESCRIPTION=Show HFs information
#===============================================================
# NAME      :  HotfixShowInfo.ksh
# Programmer:  Pedro Pavan
# Date      :  10-Jul-14
# Purpose   :  Show HFs information
#
# Changes history:
#
#  Date     |     By        | Changes/New features
# ----------+---------------+-------------------------------------
# 07-10-14    Pedro Pavan      Initial version
# 07-31-14    Pedro Pavan      Show version details
# 04-02-15    Pedro Pavan      Go to HF directory
#===============================================================

######################################
# HF Tool DB
######################################
Get_Genesis_DB() {

    GENESIS_DB="$AMC_REPOSITORY_DATABASE_USERNAME/$AMC_REPOSITORY_DATABASE_PASSWORD@$AMC_REPOSITORY_DATABASE_INSTANCE"
    echo ${GENESIS_DB}
}

######################################
# Usage
######################################
Usage() {
    EXIT_CODE=$1

    echo -e "${COLOR_YELLOW}\nUsage: ${COLOR_END}\n"
    echo "$(basename $0) [-e <env_number>] [-i <hf_id>] [-b <bundle_name>] [-s <version_statistics>]"
    echo ""
	echo "  -e   Environment Number   "
    echo "  -i   Hotfix ID            "
    echo "  -b   Bundle Name          "
    echo "  -s   Version statistics   "
    echo ""

    exit ${EXIT_CODE}
}

######################################
# Show Environment Information
######################################
Show_Env() {
    PARAM=$1
    EPOCH_DATE="01/01/1970"

    if [[ "$(hostname)" == "indlin"* ]]; then
    print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500

        SELECT DISTINCT EVT.UNIQUE_ID AS HF_ID,
               UPPER(SUBSTR(EVT.ENVIRONMENT, 1, 3)) AS PRODUCT,
               NVL(ENV.REFRESH_DATE, to_date('${EPOCH_DATE}', 'DD/MM/YYYY')) AS REFRESH_DATE
          FROM HOTFIX_EVT EVT
         INNER JOIN HOTFIX_ENVIRONMENTS ENV
            ON EVT.ENVIRONMENT = ENV.ENVIRONMENT
         WHERE EVT.ENVIRONMENT LIKE '%@indlnqw${PARAM}%'
           AND EVT.EVENT_NAME = 'DEPLOYED'
		   AND (EVT.CREATION_DATE >= ENV.REFRESH_DATE OR ENV.REFRESH_DATE IS NULL)
         ORDER BY 1 ASC;" | sqlplus -S ${HF_DB_CON} > ${TMP_FILE}
    else
    print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500

        SELECT DISTINCT EVT.UNIQUE_ID AS HF_ID,
               UPPER(SUBSTR(EVT.ENVIRONMENT, 4, 3)) AS PRODUCT,
               ENV.REFRESH_DATE AS REFRESH_DATE
          FROM HOTFIX_EVT EVT
         INNER JOIN HOTFIX_ENVIRONMENTS ENV
            ON EVT.ENVIRONMENT = ENV.ENVIRONMENT
         WHERE EVT.ENVIRONMENT LIKE '%${PARAM}@vlty%'
           AND EVT.EVENT_NAME = 'DEPLOYED'
           AND EVT.CREATION_DATE >= ENV.REFRESH_DATE
         ORDER BY 1 ASC;" | sqlplus -S ${HF_DB_CON} > ${TMP_FILE}
    fi

	if [ -s ${TMP_FILE} ]; then
        echo -e "${COLOR_MAGENTA}\n===================${COLOR_END}"
        echo -e "${COLOR_MAGENTA}     ENV#${PARAM}    ${COLOR_END}"
        echo -e "${COLOR_MAGENTA}===================${COLOR_END}"
        echo "Refreshed: $(head -1 ${TMP_FILE} | awk '{ print $3 }')"
        echo "Deployed: $(wc -l ${TMP_FILE} | awk '{ print $1 }') HF(s)"

        for product in ABP CRM OMS MCS OMN WSF AUA; do grep "${product}" ${TMP_FILE} | awk '{ print $1 }' > list_${product}.hf; done
        echo -e "${COLOR_GREEN}\nABP\t\tCRM\t\tOMS\t\tMCS\t\tOMN\t\tWSF\t\tAUA${COLOR_END}"

        MAX=$(wc -l *.hf | grep -v total | awk '{ print $1 }' | sort -n | tail -1)
        HF_EMPTY="---------"
        for line in $(seq 1 ${MAX}); do
            HF_ABP=$(sed -n "${line}p" list_ABP.hf)
            HF_CRM=$(sed -n "${line}p" list_CRM.hf)
            HF_OMS=$(sed -n "${line}p" list_OMS.hf)
            HF_MCS=$(sed -n "${line}p" list_MCS.hf)
            HF_OMN=$(sed -n "${line}p" list_OMN.hf)
            HF_WSF=$(sed -n "${line}p" list_WSF.hf)
            HF_AUA=$(sed -n "${line}p" list_AUA.hf)

            [ -z ${HF_ABP} ] && HF_ABP=${HF_EMPTY}
            [ -z ${HF_CRM} ] && HF_CRM=${HF_EMPTY}
            [ -z ${HF_OMS} ] && HF_OMS=${HF_EMPTY}
            [ -z ${HF_MCS} ] && HF_MCS=${HF_EMPTY}
            [ -z ${HF_OMN} ] && HF_OMN=${HF_EMPTY}
            [ -z ${HF_WSF} ] && HF_WSF=${HF_EMPTY}
            [ -z ${HF_AUA} ] && HF_AUA=${HF_EMPTY}

            echo -e "${HF_ABP}\t${HF_CRM}\t${HF_OMS}\t${HF_MCS}\t${HF_OMN}\t${HF_WSF}\t${HF_AUA}"
        done
		
		rm -f list_*.hf
    else
        echo "There's no HF deployed"
    fi
}

######################################
# Show Bundle Information
######################################
Show_Bundle() {
    PARAM=$1

    print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500

        SELECT ENVIRONMENT AS ENV,
               NVL(TO_CHAR(LAST_RUN, 'DD/MM/YYYY HH24:MI:SS'), 'NONE') AS LAST_RUN
          FROM HOTFIX_BUNDLES_STATUS 
         WHERE BUNDLE_NAME = '${PARAM}'
         ORDER BY LAST_RUN ASC;
    " | sqlplus -S ${HF_DB_CON} | awk '{ print $1"\t"$2" "$3 }' > ${TMP_FILE}

    if [ -s ${TMP_FILE} ]; then
        BUNDLE_DESC=$(print "
            WHENEVER SQLERROR EXIT 5
            SET FEEDBACK OFF
            SET HEADING OFF
            SET PAGES 0
            SET LINE 500

            SELECT DISTINCT BUNDLE_DESC AS DESCRIPTION
              FROM HOTFIX_BUNDLES
             WHERE BUNDLE_NAME = '${PARAM}';
        " | sqlplus -S ${HF_DB_CON})
    
        BUNDLE_COUNT=$(print "
            WHENEVER SQLERROR EXIT 5
            SET FEEDBACK OFF
            SET HEADING OFF
            SET PAGES 0
            SET LINE 500

            SELECT COUNT(BUNDLE_NAME) AS HFS
              FROM HOTFIX_BUNDLES
             WHERE BUNDLE_NAME = '${PARAM}';
        " | sqlplus -S ${HF_DB_CON} | sed 's/^[ \t]*//')

        echo -e "${COLOR_MAGENTA}\n\nHFs\tBUNDLE DESCRIPTION${COLOR_END}"
        echo -e "${BUNDLE_COUNT}\t${BUNDLE_DESC}"
        echo -e "${COLOR_GREEN}\n\nENVIRONMENT\t\tDATE TIME${COLOR_END}"
        
        cat ${TMP_FILE}

        echo -e "${COLOR_GREEN}\n\nHOTFIX ID\tORDER${COLOR_END}"
        print "
            WHENEVER SQLERROR EXIT 5
            SET FEEDBACK OFF
            SET HEADING OFF
            SET PAGES 0
            SET LINE 500       

            SELECT UNIQUE_ID,
                   ORDER_NUM 
              FROM HOTFIX_BUNDLES 
             WHERE BUNDLE_NAME = '${PARAM}'
             ORDER BY ORDER_NUM ASC;
        " | sqlplus -S ${HF_DB_CON} | awk '{ print $1"\t"$2 }'
        echo ""
    else
        echo "Bundle '${PARAM}' was not found, choose one from list below:"
        echo -e "${COLOR_MAGENTA}\nHFs\tBUNDLE NAME${COLOR_END}"

        print "
            WHENEVER SQLERROR EXIT 5
            SET FEEDBACK OFF
            SET HEADING OFF
            SET PAGES 0
            SET LINE 500

            SELECT COUNT(BUNDLE_NAME) AS HFS,
				       BUNDLE_NAME AS BUNDLE
              FROM HOTFIX_BUNDLES 
             GROUP BY BUNDLE_NAME 
             ORDER BY BUNDLE_NAME ASC;
        " | sqlplus -S ${HF_DB_CON} | awk '{ print $1"\t"$2 }'
        echo ""
    fi
}

######################################
# Show Hotfix Information
######################################
Show_HF() {
    PARAM=$1

    HF_PATH=$(find ${HOME}/hotfix/HOTFIX -name "HF_${PARAM}" -type d)
    if [ -z ${HF_PATH} ]; then
       echo -e "${COLOR_RED}\nHF was not found!\n${COLOR_END}"
        exit 1
    fi

    echo -e "${COLOR_MAGENTA}===================${COLOR_END}"
    echo -e "${COLOR_MAGENTA} HF#${PARAM}       ${COLOR_END}"
    echo -e "${COLOR_MAGENTA}===================${COLOR_END}"

    echo -e "${COLOR_GREEN}\nCREATION DATE\t\tPRODUCT\tVERSION\tOWNER\tTYPE${COLOR_END}"
    print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 500

        SELECT TO_CHAR(CREATION_DATE + 1/12, 'DD/MM/YYYY HH24:MI:SS') AS \"DATE\", 
               PRODUCT AS \"PRODUCT\",
               RELEASE AS \"VERSION\",
               CREATED_BY AS \"OWNER\",
               FIX_TYPE AS \"TYPE\"
          FROM HOTFIX_MNG 
         WHERE UNIQUE_ID = ${PARAM};
    " | sqlplus -S ${HF_DB_CON} | awk '{ print $1" "$2"\t"$3"\t"$4"\t"$5"\t"$6 }'

	echo -e "${COLOR_GREEN}\nREJECTED\tAPPROVED\tMANUAL_STEP\tAUTO_DEPLOY${COLOR_END}"
	print "
        WHENEVER SQLERROR EXIT 5
		SET FEEDBACK OFF
		SET HEADING OFF
		SET PAGES 0
		SET LINE 500
			
		SELECT
	   		DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_EVT WHERE UNIQUE_ID = M.UNIQUE_ID AND EVENT_NAME = 'REJECTED'),0,'NO',1,'YES','YES') AS REJECTED,
	    	DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_EVT WHERE UNIQUE_ID = M.UNIQUE_ID AND EVENT_NAME = 'APPROVED'),0,'NO',1,'YES','YES') AS APPROVED,      
   			DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = M.UNIQUE_ID AND UNIQUE_ID IN 
   				(SELECT UNIQUE_ID FROM HOTFIX_AP_RELATIONS WHERE UNIQUE_ID = M.UNIQUE_ID AND PARAM_ID = 1 AND PARAM_VALUE = 'YES')),0, 'NO',1, 'YES','YES') AS MANUAL_STEP,
   			DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = M.UNIQUE_ID AND UNIQUE_ID NOT IN (SELECT UNIQUE_ID FROM HOTFIX_AUTO_DEPLOY)),0,'YES',1,'NO','NO') AS AUTO_DEPLOY
 		  FROM HOTFIX_MNG M
		WHERE M.UNIQUE_ID = ${PARAM};
	" | sqlplus -S ${HF_DB_CON} | awk '{ print $1"\t\t"$2"\t\t"$3"\t\t"$4 }'

	echo -e "${COLOR_GREEN}\nINSTRUCTIONS${COLOR_END}"
	INSTRUCTIONS="instructions.tmp"
	print "
        WHENEVER SQLERROR EXIT 5
		SET FEEDBACK OFF
		SET HEADING OFF
		SET PAGES 0
		SET LINE 500

		SELECT REPLACE(REPLACE(instructions, '&#13', ';'), ';;', ';') FROM hotfix_mng WHERE unique_id = ${PARAM};		
	" | sqlplus -S ${HF_DB_CON} > ${INSTRUCTIONS}
	
	#[ "$(rev ${INSTRUCTIONS} | cut -c1)" == ";" ] && INSTRUCTIONS=$(echo ${INSTRUCTIONS} | sed s/.$//)
	cat ${INSTRUCTIONS} | tr ';' '\n' && rm ${INSTRUCTIONS}
		
    echo -e "${COLOR_GREEN}\nEVENT NAME\tDEPLOY\tENVIRONMENT\t\tDATE TIME\t\tFILE${COLOR_END}"
    print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 5000

        SELECT DECODE(EVENT_NAME,
                    'SIGNED', '<SIGNED>',
                    'FAILED', '#FAILED#',
                    EVENT_NAME) AS EVENT,
               REPLACE(DEPLOY_TYPE, 'CUSTOM_DEPLOY', 'CUSTOM') AS DEPLOY,
               REPLACE(ENVIRONMENT, 'N/A', '*****************') AS ENV ,
               TO_CHAR(CREATION_DATE + 1/12, 'DD/MM/YYYY HH24:MI:SS') AS \"CREATION DATE TIME\",
               REPLACE(FILE_NAME,   'N/A', '-') AS FILES
          FROM HOTFIX_EVT
         WHERE UNIQUE_ID = ${PARAM}
         AND event_name in ('DEPLOYED', 'FAILED', 'APPROVED', 'UNDEPLOYED', 'REJECTED')
         ORDER BY CREATION_DATE ASC;

    " | sqlplus -S ${HF_DB_CON} | awk '{ print $1"\t"$2"\t"$3"\t"$4" "$5"\t"$6 }'

    echo -e "${COLOR_GREEN}\nFULL PATH${COLOR_END}"
    echo -e "${HF_PATH}"

	echo -e "${COLOR_GREEN}\nFILES${COLOR_END}"
    ls -1 ${HF_PATH}/ | grep -v "README.txt"
	
    echo ""
}

######################################
# Show Version Information
######################################
Show_Statistics() {
    PARAM=$1    

	COUNT=$(print "
        WHENEVER SQLERROR EXIT 5
        SET FEEDBACK OFF
        SET HEADING OFF
        SET PAGES 0
        SET LINE 5000
		
		SELECT COUNT(release) FROM hotfix_mng WHERE release = '${PARAM}';	
	" | sqlplus -S ${HF_DB_CON})
	
	if [ ${COUNT} -ne 0 ]; then
	
    	echo -e "${COLOR_MAGENTA}===================${COLOR_END}"
	    echo -e "${COLOR_MAGENTA} VERSION#${PARAM}      ${COLOR_END}"
    	echo -e "${COLOR_MAGENTA}===================${COLOR_END}"
	
		echo -e "${COLOR_GREEN}\nHFs\tTYPE${COLOR_END}"
		print "
        	WHENEVER SQLERROR EXIT 5
	        SET FEEDBACK OFF
        	SET HEADING OFF
	        SET PAGES 0
        	SET LINE 5000
		
			SELECT FIX_TYPE, COUNT(UNIQUE_ID)
			   FROM HOTFIX_MNG
			 WHERE RELEASE = '${PARAM}'
			 GROUP BY FIX_TYPE
			 ORDER BY FIX_TYPE ASC;
		" | sqlplus -S ${HF_DB_CON} | awk '{ print $2"\t"$1 }'
		
		echo -e "${COLOR_GREEN}\nINFO${COLOR_END}"
		print "
        	WHENEVER SQLERROR EXIT 5
	        SET FEEDBACK OFF
        	SET HEADING OFF
	        SET PAGES 0
        	SET LINE 5000

			SELECT 'TOTAL;' || COUNT(unique_id) FROM hotfix_mng WHERE release = '${PARAM}';
			SELECT 'FIRST;' || MIN(unique_id) FROM hotfix_mng WHERE release = '${PARAM}';
			SELECT 'LAST;' || MAX(unique_id) FROM hotfix_mng WHERE release = '${PARAM}';
		"| sqlplus -S ${HF_DB_CON} | awk -F ';' '{ print $1"\t"$2 }'
	else
    	echo -e "${COLOR_MAGENTA}===================${COLOR_END}"
	    echo -e "${COLOR_MAGENTA} ALL VERSIONS              ${COLOR_END}"
    	echo -e "${COLOR_MAGENTA}===================${COLOR_END}"
		
		echo -e "${COLOR_GREEN}\nVERSION\t\tHFs${COLOR_END}"
		print "
			WHENEVER SQLERROR EXIT 5
			SET FEEDBACK OFF
			SET HEADING OFF
			SET PAGES 0
			SET LINE 5000
			
			SELECT release, COUNT(unique_id)
  			  FROM hotfix_mng
 			 GROUP BY release
 		     ORDER BY release ASC;
		" | sqlplus -S ${HF_DB_CON} | awk '{ print $1"\t\t"$2 }'
		
		echo -e "${COLOR_GREEN}\nHFs\tTYPE${COLOR_END}"
		print "
        	WHENEVER SQLERROR EXIT 5
	        SET FEEDBACK OFF
        	SET HEADING OFF
	        SET PAGES 0
        	SET LINE 5000
		
			SELECT FIX_TYPE, COUNT(UNIQUE_ID)
			   FROM HOTFIX_MNG
			 GROUP BY FIX_TYPE
			 ORDER BY FIX_TYPE ASC;
		" | sqlplus -S ${HF_DB_CON} | awk '{ print $2"\t"$1 }'
		
		echo -e "${COLOR_GREEN}\nINFO${COLOR_END}"
		print "
        	WHENEVER SQLERROR EXIT 5
	        SET FEEDBACK OFF
        	SET HEADING OFF
	        SET PAGES 0
        	SET LINE 5000

			SELECT 'TOTAL;' || COUNT(unique_id) FROM hotfix_mng;
			SELECT 'FIRST;' || MIN(unique_id) FROM hotfix_mng;
			SELECT 'LAST;' || MAX(unique_id) FROM hotfix_mng;
		"| sqlplus -S ${HF_DB_CON} | awk -F ';' '{ print $1"\t"$2 }'
	fi
}

######################################
# Main
######################################
cd ${HOME}/Scripts/hotfix/info/

COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
COLOR_GREEN="\033[32m"
COLOR_MAGENTA="\033[35m"
COLOR_END="\033[0m"

if [ $# -ne 2 ]; then
    Usage 1
fi

HF_DB_CON=$(Get_Genesis_DB)
RUN_MODE="?"
OPTION="?"
TMP_FILE="./data.tmp"

while getopts ":e:i:b:s:" opt
do
    case "${opt}" in
        e) RUN_MODE="E" ; OPTION=${OPTARG} ;;
        i) RUN_MODE="I" ; OPTION=${OPTARG} ;;
        b) RUN_MODE="B" ; OPTION=${OPTARG} ;;
        s) RUN_MODE="S" ; OPTION=${OPTARG} ;;
        *) RUN_MODE="?" ; OPTION=${OPTARG} ;;
    esac 
done

shift $(($OPTIND -1))

case "${RUN_MODE}" in
	"E") Show_Env ${OPTION}     ;;
    "I") Show_HF ${OPTION}      ;;
    "B") Show_Bundle ${OPTION}  ;;
    "S") Show_Statistics ${OPTION} ;;
      *) Usage 1                ;;
esac

rm -f ${TMP_FILE}
exit 0
