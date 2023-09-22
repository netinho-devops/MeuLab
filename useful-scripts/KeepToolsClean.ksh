#!/bin/ksh
#====================================================================
# Name      :  KeepToolsClean.ksh
# Author    :  Ricardo Gesuatto <dricardo@amdocs.com>
# Date      :  19-May-2015
# Purpose   :  Clean non-essential files from Tools home directory
#
# Syntax    :  KeepToolsClean.ksh -d <tools_home> -i <list_file> 
#
# Changes history:
#
#  Date     |           By         | Changes/New features
# ----------+------------------+-------------------------------------
# 20-05-15    Ricardo Gesuatto        Parametrization for basic usage
# 19-05-15    Ricardo Gesuatto        Initial version
# ----------+------------------+-------------------------------------
#
# Possible improvements:
#   - Review path escaping / quoting (whether and where it
#       it is really necessary)
#
#====================================================================

set -u
set -o pipefail


TODAY="$(date +%Y-%m-%d)"

TOOLS_HOME=""
LISTFILE=""
TEMP_PATH=""
LOGFILE=""
SUPPRESS="NO"


Usage() {
    echo ""
    echo "Usage: $(basename $0) -d <tools_home> -i <list_file>         "
    echo "Example: $(basename $0) -d \"/my_nas/market/market_tools/\" -i \"filelist.txt\""
    echo ""
    echo "  -d   Tools Home directory                        "
    echo "  -i   Input File listing what should be kept in place   "
    echo ""
    echo "  -o   Output Log file (optional)  "
    echo "       Defaults to TOOLS_HOME/scripts/utils/filesystem/cleanfiles.log "
    echo ""
    echo "  -t   Temporary destination directory for (optional)  "
    echo "       Defaults to TOOLS_HOME/temp " 
    echo ""
    echo "  -s   Suppress positive output messages (optional) "
    echo ""
}


while getopts ":d:i:o:t:s" opt
do
    case "${opt}" in
        d) [ ! -z ${OPTARG} ] && TOOLS_HOME=${OPTARG} ;;
        i) [ ! -z ${OPTARG} ] && LISTFILE=${OPTARG} ;;
        o) [ ! -z ${OPTARG} ] && LOGFILE=${OPTARG} ;;
        s) SUPPRESS="YES" ;;
        t) [ ! -z ${OPTARG} ] && TEMP_PATH=${OPTARG} ;;
        *)  Usage; exit 80 ;;
    esac
done

if [ "${TOOLS_HOME}" == "" ] || [ ! -d "${TOOLS_HOME}" ] ; then
    echo "[$(date +"%Y-%m-%d %R")] Fatal error: Must define a valid TOOLS_HOME directory. Aborting." | tee -a ${LOGFILE}
    Usage
    exit 98
fi

if [ "${TEMP_PATH}" == "" ]; then
    TEMP_PATH="${TOOLS_HOME}/temp"
fi

if [ "${LOGFILE}" == "" ]; then
    LOGFILE="${TOOLS_HOME}/scripts/utils/filesystem/cleanfiles.log"
fi

if [ ! -f "${LOGFILE}" ]; then
    mkdir -p $(dirname ${LOGFILE})
    touch ${LOGFILE}
    if [ $? != 0 ]; then
        echo "[$(date +"%Y-%m-%d %R")] Fatal error: Could not create log. Aborting."
        exit 99
    fi
    echo "[$(date +"%Y-%m-%d %R")] Log created" | tee -a ${LOGFILE}
elif [ "$(cat ${LOGFILE} | wc -l)" -gt 1000 ] ; then
    mv "${LOGFILE}" "${LOGFILE}.temp"
    tail -n 500 ${LOGFILE}.temp >> ${LOGFILE}
    rm ${LOGFILE}.temp
    echo "[$(date +"%Y-%m-%d %R")] Log partly rotated" | tee -a ${LOGFILE}
fi

if [ "${LISTFILE}" == "" ]; then
    echo "[$(date +"%Y-%m-%d %R")] Fatal error: No list file defined. Aborting." | tee -a ${LOGFILE}
    Usage
    exit 97
fi

if [ ! -f "${LISTFILE}" ]; then
    echo "[$(date +"%Y-%m-%d %R")] Fatal error: Invalid list file. Aborting." | tee -a ${LOGFILE}
    exit 96
fi

if [ ! -d "${TEMP_PATH}" ]; then
    mkdir -p ${TEMP_PATH}
    if [ $? != 0 ]; then
        echo "[$(date +"%Y-%m-%d %R")] Fatal error: Invalid temporary directory. Aborting." | tee -a ${LOGFILE}
        exit 95
    fi
fi

if [ "${SUPPRESS}" == "NO" ]; then
    echo -e "[$(date +"%Y-%m-%d %R")] Using listfile: ${LISTFILE}" | tee -a ${LOGFILE}
fi


TO_KEEP="$(cat ${LISTFILE} | egrep -v "^#")"

while read -r line; do
    if [[ "${TO_KEEP}" =~ ""${line}"" ]]; then
        if [ "${SUPPRESS}" == "NO" ]; then
		    echo "[$(date +"%Y-%m-%d %R")] File ${line} found in listfile. Keeping it." | tee -a ${LOGFILE}
        fi
    else
        echo "[$(date +"%Y-%m-%d %R")] File ${line} NOT found in listfile. MOVING it." | tee -a ${LOGFILE}
        mv ${TOOLS_HOME}/${line} ${TEMP_PATH}/${line}-${TODAY}
    fi
done < <( ls -A -1 -b ${TOOLS_HOME} )

if [ "${SUPPRESS}" == "NO" ]; then
    echo "[$(date +"%Y-%m-%d %R")] Cleanup successful." | tee -a ${LOGFILE}
fi

