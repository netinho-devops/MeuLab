
#!/bin/ksh -u

#NAME:		    : ServerMonitoring.ksh
#DESCRIPTION	: Get server name and monitor - Hardware/FS/performance/env numbers/etc...
#USAGE		    : ServerMonitoring.ksh <debug/log>
#WRITER 	    : Ori Aviv
#DATE 		    : 12-2015
###################################################################################################################

RUNNING_MODE=$1
PROJECT_NAME=$2
SERVER_NAME=$3

#constants
LOG_FILE=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/Logs/ServerMonitoring.text
TEMP_FILE=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/TEMP_FILE
TEMP_FILE2=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/TEMP_FILE2
TEMP_FILE3=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/TEMP_FILE3
TEMP_FILE4=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/TEMP_FILE4
HP_UX_PERFORMANCE_FILE=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/performance.txt
PROJECT_ACCOUNT="zigtools"
ST_ENVS_NUMBER_START=40
MASTER_ENVS_NUMBER_START=80



#global Variables
#env number
_envNumbersArray=""
_envNumbersIndex=1
_envNumberDEVArray=""
_envNumbersDEVIndex=1
_envNumbersSTArray=""
_envNumbersSTIndex=1
_envNumbersMASTERArray=""
_envNumbersMASTERIndex=1

#FS
_FSNameArray=""
_FSNameIndex=1
_FSUsage=""
_FSUsageIndex=1

if [ $# -lt 3 ]
  then
  echo ""
  echo "usage: ./ServerMonitoring.ksh   [RUNNING_MODE]   [PROJECT_NAME]   [SERVER_NAME]   [SERVER_TYPE]   [OPTIONAL:USER_MAIL] "
  echo ""
  echo "   for example:"
  echo "   ./ServerMonitoring.ksh debug zig illin2529 INT ori.aviv@amdocs.com"
  echo "   ./ServerMonitoring.ksh log zig ilsun037 DB ori.aviv@amdocs.com"
  echo ""
  exit 0
fi

function preCondition
{
  debugMode "function" "                     prepareEnvList"
  checkFile ${LOG_FILE}
  checkFile ${TEMP_FILE}
  checkFile ${TEMP_FILE2}
  checkFile ${TEMP_FILE3}
  checkFile ${TEMP_FILE4}


  ###########
  # I N I T #
  ###########

  OS=`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} "uname -s"`
  debugMode "OS       " "                    ${OS}"


  case ${OS} in
  SunOS)
          export DF="/usr/bin/df -k"
          export CPU_NUM="/usr/sbin/psrinfo -pv | grep processor | wc -l"
          export CPU_SPEED="/usr/sbin/psrinfo -pv | grep chipid | tail -1 | awk '{print \$2 \$3 \$4 \$5 \$6}'"
          export MEMORY_TOTALL="/etc/prtconf -v | grep Memory | awk '{print \$3\" \"\$4}'"
          #real time
          #TODO - Should be checked
          export MEMORY_FREE_RT="/usr/bin/vmstat | tail -1 | awk '{print \$5}'"
          #TODO - Should be checked
          export MEMORY_USAGE_RT="/usr/bin/vmstat | tail -1 | awk '{print \$4}'"
          export CPU_PERFORMANCE_RT="/usr/bin/vmstat | tail -1 | awk '{print \$20}'"
          ;;
  AIX)
          export DF="/usr/bin/df"
          ;;
  HP-UX)
          export DF="/usr/bin/bdf"
          export CPU_NUM="/usr/contrib/bin/machinfo | grep Processor | awk '{print \$1}'"
          export CPU_SPEED="/usr/contrib/bin/machinfo | grep Processor | awk '{print \$6 \$7 \$8 \$9}'"
          export MEMORY_TOTALL="/usr/contrib/bin/machinfo | grep Memory | awk '{print \$2\" \"\$3}'"
          #real time
          export CPU_PERFORMANCE_RT="/usr/bin/vmstat | tail -1 | awk '{print \$16}'"
          #TODO - Should be checked
          export MEMORY_USAGE_RT="/usr/bin/vmstat | tail -1 | awk '{print \$4}'"
          #TODO - Should be checked
          export MEMORY_FREE_RT="/usr/bin/vmstat | tail -1 | awk '{print \$5}'"
          ;;
  Linux)
          export DF="/bin/df"
          export CPU_NUM="cat /proc/cpuinfo | grep processor | wc -l"
          export CPU_SPEED="cat /proc/cpuinfo | grep MHz | tail -1 | awk '{print \$4}'"
          export MEMORY_TOTALL="free -m | grep Mem | awk '{print \$2}'"
          #real-time
          export CPU_PERFORMANCE_RT="/usr/bin/mpstat | | grep all | awk '{print \$4}'"
          export MEMORY_USAGE_RT="free -m | grep Mem | awk '{print \$3}'"
          export MEMORY_FREE_RT="free -m | grep Mem | awk '{print \$4}'"
          ;;
  *)
    echo "illegal OS"
          ;;
  esac
}

function debugMode
{
    parameter=$1
    value=$2
    if [ "${RUNNING_MODE}" = "debug" ]
      then
      echo "${parameter}" "${value}"
    else
      echo "${parameter}  ${value}" >> ${LOG_FILE}
    fi
}

function checkFile
{
    fileName=$1
    if [ ! -f ${fileName} ]
    then
            touch ${fileName}
    else
            rm ${fileName}
            touch ${fileName}
    fi
}


function prepareEnvList
{
  debugMode "function" "                     prepareEnvList"
  ssh -n ${SERVER_NAME} "cat /etc/passwd | cut -d ":" -f 1 | grep "^${PROJECT_NAME}" | sed 's/[^0-9]*//g' | sed '/^$/d'" > ${TEMP_FILE}
  #debugMode "${TEMP_FILE}" "\n\n`cat ${TEMP_FILE}`"
  cat ${TEMP_FILE} | sort -n | uniq > ${TEMP_FILE2}
  #debugMode "${TEMP_FILE2}" "\n\n`cat ${TEMP_FILE2}`"

  _envNumbersIndex=1
  while read line
  do
    #debugMode "line ${_envNumbersIndex}                      " "  ${line}"
    _envNumbersArray[${_envNumbersIndex}]="${line}"
    _envNumbersIndex=$((_envNumbersIndex+1))
  done < "${TEMP_FILE2}"

  i=1
  while [[ ${i} -lt ${_envNumbersIndex} ]]
  do
    if [[ ${_envNumbersArray[${i}]} -lt ${ST_ENVS_NUMBER_START} ]]
      then

      _envNumbersDEVArray[${_envNumbersDEVIndex}]=${_envNumbersArray[${i}]}
      _envNumbersDEVIndex=$((_envNumbersDEVIndex+1))
    elif [[ ${_envNumbersArray[${i}]} -lt ${MASTER_ENVS_NUMBER_START} && ${_envNumbersArray[${i}]} -ge ${ST_ENVS_NUMBER_START} || ${_envNumbersArray[${i}]} -eq 90 ]]
        then
        _envNumbersSTArray[${_envNumbersSTIndex}]=${_envNumbersArray[${i}]}
        _envNumbersSTIndex=$((_envNumbersSTIndex+1))

    else
      _envNumbersMASTERArray[${_envNumbersMASTERIndex}]=${_envNumbersArray[${i}]}
      _envNumbersMASTERIndex=$((_envNumbersMASTERIndex+1))
    fi
    i=$((i+1))
  done



  debugMode "env numbers of DEV array" ""
  i=1
  while [ ${i} -lt ${_envNumbersDEVIndex} ]
  do
    debugMode "_envNumbersDEVArray[${i}]       " "${_envNumbersDEVArray[${i}]}"
    i=$((i+1))
  done

  debugMode "env numbers of ST array" ""
  i=1
  while [ ${i} -lt ${_envNumbersSTIndex} ]
  do
    debugMode "_envNumbersSTArray[${i}]       " "${_envNumbersSTArray[${i}]}"
    i=$((i+1))
  done

  debugMode "env numbers of MASTER array" ""
  i=1
  while [ ${i} -lt ${_envNumbersMASTERIndex} ]
  do
    debugMode "_envNumbersMASTERArray[${i}]    " "${_envNumbersMASTERArray[${i}]}"
    i=$((i+1))
  done

}


function prepareFSlist
{
  debugMode "function" "                    prepareFSlist"
  debugMode "ssh     " "                    ssh ${PROJECT_ACCOUNT}@${SERVER_NAME}"
  ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} "${DF}" > ${TEMP_FILE}
  sed '/^$/d' ${TEMP_FILE} | egrep "^/" > ${TEMP_FILE4}
  cat ${TEMP_FILE4} > ${TEMP_FILE}



  cat ${TEMP_FILE} | awk '{print $6}' > ${TEMP_FILE2}
  cat ${TEMP_FILE} | awk '{print $5}' > ${TEMP_FILE3}

  sed '/^$/d' ${TEMP_FILE2} > ${TEMP_FILE4}
  cat ${TEMP_FILE4} > ${TEMP_FILE2}

  sed '/^$/d' ${TEMP_FILE3} > ${TEMP_FILE4}
  cat ${TEMP_FILE4} > ${TEMP_FILE3}

  #debugMode "`cat ${TEMP_FILE}`" ""
  #debugMode "`cat ${TEMP_FILE2}`" ""
  #debugMode "`cat ${TEMP_FILE3}`" ""



  #clean empty lines
  #sed -i '/^$/d' ${TEMP_FILE2}
  #sed -i '/^$/d' ${TEMP_FILE3}

  index=1
  while read line
  do
    #if [[ ${index} -eq 1 ]]
    #then
    #  echo $index
    #  index=$((index+1))
    #  continue
    #fi
    #debugMode "line ${index}                      " "  ${line}"

    #implementation

    _FSNameArray[${_FSNameIndex}]="${line}"
    _FSNameIndex=$((_FSNameIndex+1))
    index=$((index+1))
  done < "${TEMP_FILE2}"

  index=1
  while read line
  do
    #if [[ ${index} -eq 1 ]]
    #then
    #  echo $index
    #  index=$((index+1))
    #  continue
    #fi
    #debugMode "line ${index}                      " "  ${line}"


    #implementation
    _FSUsageArray[${_FSUsageIndex}]="${line}"
    _FSUsageIndex=$((_FSUsageIndex+1))
    index=$((index+1))
  done < "${TEMP_FILE3}"


  debugMode "FS name" ""
  i=1
  while [ ${i} -lt ${_FSNameIndex} ]
  do
    debugMode "${i}" "${_FSNameArray[${i}]}"
    i=$((i+1))
  done


  debugMode "FS usage" ""
  i=1
  while [ ${i} -lt ${_FSUsageIndex} ]
  do
    debugMode "${i}" "${_FSUsageArray[${i}]}"
    i=$((i+1))
  done
}


function preparePhysicalAndRTCPUMemlist {



  OS=`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} "uname -s"`
  debugMode "OS       " "                    ${OS}"

  case ${OS} in
  SunOS)
          debugMode "SunOS case" ""
          debugMode "CPU_NUM                      " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${CPU_NUM}`"
          debugMode "CPU_SPEED                    " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${CPU_SPEED}`"
          debugMode "MEMORY_TOTALL                " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${MEMORY_TOTALL}`"
          debugMode "MEMORY_USAGE_RT              " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${MEMORY_USAGE_RT}`"
          debugMode "MEMORY_FREE_RT               " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${MEMORY_FREE_RT}`"
          ;;
  AIX)
          debugMode "AIX case" ""
          ;;
  HP-UX)
          debugMode "HP-UX case" ""
          debugMode "CPU_NUM                      " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${CPU_NUM}`"
          debugMode "CPU_SPEED                    " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${CPU_SPEED}`"
          debugMode "MEMORY_TOTALL                " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${MEMORY_TOTALL}`"
          debugMode "MEMORY_USAGE_RT              " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${MEMORY_USAGE_RT}`"
          debugMode "MEMORY_FREE_RT               " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${MEMORY_FREE_RT}`"
          ;;
  Linux)
          debugMode "Linux case" ""
          debugMode "CPU_NUM                      " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${CPU_NUM}`"
          debugMode "CPU_SPEED                    " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${CPU_SPEED}`"
          debugMode "MEMORY_TOTALL                " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${MEMORY_TOTALL}`"
          debugMode "MEMORY_USAGE_RT              " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${MEMORY_USAGE_RT}`"
          debugMode "MEMORY_FREE_RT               " "`ssh ${PROJECT_ACCOUNT}@${SERVER_NAME} ${MEMORY_FREE_RT}`"
          ;;
  *)
    echo "illegal OS"
          ;;
  esac


}


############     Main - Start   ############
preCondition
prepareEnvList
prepareFSlist
preparePhysicalAndRTCPUMemlist
############     Main - End     ############
