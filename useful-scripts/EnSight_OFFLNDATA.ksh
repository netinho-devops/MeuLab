#!/usr/bin/ksh
#===============================================================
# NAME      :  EnSight_OFFLNDATA.ksh
# Programmer:  Pedro Pavan
# Date      :  07-Dec-15
# Purpose   :  Populate ENS_OFFLN_DATA table
#
# Changes history:
#
#  Date     |     By        | Changes/New features
# ----------+---------------+-----------------------------------
# 12-07-15    Pedro Pavan       Initial version
#===============================================================

##############################################
# Variables & Functions
##############################################
SQL_FILE="$(basename $0).sql"
echo "truncate table ENS_OFFLN_DATA;" > ${SQL_FILE}

LOG_FILE="$(basename $0).log"
> ${LOG_FILE}

##############################################
# Physical
##############################################
MACHINES="indlin3555,indlin3401,indlin3402,indlin3403"
for machine in $(echo ${MACHINES} | tr ',' '\n'); do
		for account in $(ssh vivtools@${machine} "egrep '^viv' /etc/passwd | cut -d ':' -f 1 | grep -v vivtools"); do
				env_num=$(echo ${account} | tr -d '[a-z]')
				phase="NA"

				case ${env_num} in
					[1-9]) phase="UT" ; owner="Master" ;; #  1-9
				   1[0-9]) phase="UT" ; owner="UT";; # 10-19
				   2[0-9]) phase="UT" ; owner="UT";; # 20-29
				   3[0-9]) phase="UT" ; owner="UT";; # 30-39
				   4[0-9]) phase="SST" ; owner="SST";; # 40-49
				   5[0-9]) phase="SST" ; owner="SST";; # 50-59
				   6[0-9]) phase="SST" ; owner="SST";; # 60-69
				   7[0-9]) phase="ST" ; owner="ST";; # 70-79
				   8[0-9]) phase="ST" ; owner="ST";; # 80-89
				   9[0-9]) phase="Infra" ; owner="Infra";; # 90-99
				        *) phase="NA"  ;; # out of range
				esac

				echo "[$(date +%c)] ${account}@${machine} | ${env_num} | ${phase} | ${owner}" >> ${LOG_FILE}
				echo "insert into ENS_OFFLN_DATA (ENV_USER, ENV_HOST, PROPERTY, VALUE) values ('${account}', '${machine}', 'Owner', '${owner}');" >> ${SQL_FILE}
				echo "insert into ENS_OFFLN_DATA (ENV_USER, ENV_HOST, PROPERTY, VALUE) values ('${account}', '${machine}', 'Type', '${phase}');" >> ${SQL_FILE}
				echo -n "."
        done
done

##############################################
# Virtual
##############################################
echo ""
owner="CST"
phase="CST"
for virtual in $(seq 301 400); do
	machine="indlnqw${virtual}"

	for vaccount in abpwrk1 crmwrk1 omswrk1 amswrk1 slroms1 slrams1; do
		echo "[$(date +%c)] ${vaccount}@${machine} | ${machine} | ${phase} | ${owner}" >> ${LOG_FILE}
		echo "insert into ENS_OFFLN_DATA (ENV_USER, ENV_HOST, PROPERTY, VALUE) values ('${vaccount}', '${machine}', 'Owner', '${owner}');" >> ${SQL_FILE}
		echo "insert into ENS_OFFLN_DATA (ENV_USER, ENV_HOST, PROPERTY, VALUE) values ('${vaccount}', '${machine}', 'Type', '${phase}');" >> ${SQL_FILE}
		echo -n "."
	done
done

##############################################
# SQL file
##############################################
echo -e "\n[$(date +%c)] Executing SQL file" | tee -a ${LOG_FILE}
cat ${SQL_FILE} | sqlplus -S ${TOOLS_DB_USER}/${TOOLS_DB_PASSWORD}@${TOOLS_DB_INSTANCE} > ${LOG_FILE} 2>&1
if [ $? -eq 0 ]; then
		echo "[$(date +%c)] Ended successfully" | tee -a ${LOG_FILE}
else
		echo "[$(date +%c)] Finished with errors" | tee -a ${LOG_FILE}
fi

echo -e "\nSQL: ${SQL_FILE} [$(wc -l ${SQL_FILE} | awk '{ print $1 }') lines]"
echo "LOG: ${LOG_FILE}"
echo "commit;" >> ${SQL_FILE}

exit 0
