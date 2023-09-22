#!/bin/ksh -u

#NAME:		    : AutoServersDiagram.ksh
#DESCRIPTION	: login to ensight DB and generate auto server diagram.
#USAGE		    : AutoServersDiagram.ksh <debug/log> <automatic/manual>
#WRITER 	    : Ori Aviv
#DATE 		    : 09-2015
###################################################################################################################

if [ $# -lt 2 ]
  then
  echo ""
  echo "please supply RUNNING-MODE and RUNNING-STATUS"
  echo ""
  echo "   for example:"
  echo "   ./AutoServersDiagram.ksh debug manual"
  echo "   ./AutoServersDiagram.ksh log manual"
  echo "   ./AutoServersDiagram.ksh log automatic"
  echo ""
  echo "   Optional"
  echo "   ./AutoServersDiagram.ksh log automatic User_Email"
  exit 0
fi


RUN_MODE=${1}
RUNNING_STATUS=${2}



########	Images Definitions	########
IMAGE_SERVER_URL="http://images.clipartpanda.com/server-clipart-RTGK5rgTL.png"
IMAGE_DB_SERVER_URL="http://www.advess.net/media/database_server1.jpg"
IMAGE_CC_SERVER_URL="http://cliparts101.com/files/707/9E15EF747BCA9FC93D8E87F8912884BD/Application_Server.png"
########	Mail Definitions	########
TO_MAIL=""
FROM_MAIL=""

########	HTML definitions	########
IMAGE_SERVER_WIDTH=auto
IMAGE_SERVER_HEIGHT=100
IMAGE_DB_SERVER_WIDTH=auto
IMAGE_DB_SERVER_HEIGHT=50
DB_ROWS=25
INT_ROWS=5

########	files	########
LOG_FILE="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/Logs/AutoServersDiagram.log"
HTML_FILE="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/HTML/AutoServersDiagram.html"
MANUAL_RUNNING_DEFINITION="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/Definition/ATT_SERVERS_DEFINITIONS_FOR_MANUALLY_RUNNING.txt"
AUTOMATIC_RUNNING_DEFINITION="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/Definition/ATT_SERVERS_DEFINITION_FOR_AUTONOMOUS_DIAGRAM.txt"
PROJECT_DEFINITION="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/Definition/PROJUCT_DETAILS.txt"
TEMP_FILE=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/TEMP_FILE
TEMP_ROW=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/TEMP_ROW
INT_ARRAY=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/INT_SERVERS_ARRAY
DB_ARRAY=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/DB_SERVERS_ARRAY
CC_ARRAY=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/CC_SERVERS_ARRAY
DB_INSTANCES_DIR=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/DBInstances
PRODUCTS_DIR=${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/Products

########	Global variables	########
_projectName=""
_projectDL=""
_projectEnsightDB=""
_toolServer=""
_intArray=""
_intIndex=1
_DBArray=""
_DBIndex=1

_instancesArrayTemp=""
_indexInstancesArrayTemp=1
_DBArrayTemp=""
_indexDBArrayTemp=1

_ccArray=""
_ccBooleanArray=""
_ccIndex=1
_DBArray=""
_DBIndex=1

_htmlContent=""
_dbEnsightParameters="false"
_toolServerParameters="false";
_queryParameters="false"
_queryDBParameters="false"
_projectDLParameters="false"
_projectNameParameters="false"
_CCNameParameters="false"
#Array from DB
_integrationServersList=""
_integrationServersLastIndex=0
#Defention from Automatic
_dbEnsightParametersFromAutomaticDefinition=""
_toolServerFromAutomaticDefinition=""
_integrationAccountsAndServersQueryFromAutomaticDefinition=""
_InstancesQueryFromAutomaticDefinition=""
_projectDLFromAutamaticDefinition=""
_projectNameFromAutamaticDefinition=""


function preCondition
{
  debugMode "@@@function@@@" "preCondition"
	checkFile "${HTML_FILE}"
	checkFile "${LOG_FILE}"
  checkFile "${TEMP_FILE}"
  checkFile "${TEMP_ROW}"
  checkFile "${INT_ARRAY}"
  checkFile "${DB_ARRAY}"
  checkFile "${CC_ARRAY}"
  checkFile "${PROJECT_DEFINITION}"
  checkDirectory "${DB_INSTANCES_DIR}"
  checkDirectory "${PRODUCTS_DIR}"
  debugMode IMAGE_SERVER_URL "${IMAGE_SERVER_URL}"
	debugMode	IMAGE_NETWORK_URL "${IMAGE_DB_SERVER_URL}"
}


function parserMachine
{
  debugMode "@@@function@@@" "generateManualDiagram"
  index=1
  paramToHandle=1
  continueFlag=false
  generatedFileForServerProduct=false
  while read line
    do
      debugMode "line & ${index}" "${line}"

        if [ "${continueFlag}" = "true" ]
          then
          debugMode "paramToHandle" ${paramToHandle}
          case ${paramToHandle} in
            #project name
            1)
              _projectName=${line}
              debugMode "_projectName" "${_projectName}"
              continueFlag=false
              paramToHandle=$((paramToHandle+1))
              continue
            ;;
            #project DL
            2)
              _projectDL=${line}
              debugMode _projectDL "${_projectDL}"
              continueFlag=false
              paramToHandle=$((paramToHandle+1))
              continue
            ;;
            #project ensight DB
            3)
              _projectEnsightDB=${line}
              debugMode _projectEnsightDB "${_projectEnsightDB}"
              continueFlag=false
              paramToHandle=$((paramToHandle+1))
              continue
            ;;
            #project INT servers
            4)
              if [ "${line}" = "INT_SERVERS_LIST_END" ]
                then
                continueFlag=false
                paramToHandle=$((paramToHandle+1))
              else
                echo "${line}" >> ${INT_ARRAY}
                debugMode "INT_ARRAY_FILE" "${line}"
                _intArray[${_intIndex}]=${line}
                debugMode "INT_ARRAY" "${_intArray[${_intIndex}]}"
                debugMode "INT_INDEX" "${_intIndex}"
                _intIndex=$((_intIndex+1))

              fi
              continue
            ;;
            #project products per INT servers
            5)

              if [ "${generatedFileForServerProduct}" = "false" ]
                then
                checkFile ${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/Products/${line}_products.txt
                eval serverProducts="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/Products/${line}_products.txt"
                generatedFileForServerProduct=true
                continue
                #file for server products has been created
              fi

              if [ "${line}" = "PRODUCTS_PER_SERVER_END" ]
              then
                  continueFlag=false
                  generatedFileForServerProduct=false
                  continue
              else
                  echo "${line}" >> ${serverProducts}
                  continue
              fi
            ;;

            #project DB servers
            6)

              if [ "${line}" = "DB_SERVERS_LIST_END" ]
                then
                continueFlag=false
                paramToHandle=$((paramToHandle+1))
              else
                echo "${line}" >> ${DB_ARRAY}
                _DBArray[${_DBIndex}]=${line}
                debugMode "DB_ARRAY" "${line}"
                debugMode "DB_ARRAY" "${_DBArray[${_DBIndex}]}"
                debugMode "DB_INDEX" "${_DBIndex}"
                _DBIndex=$((_DBIndex+1))
              fi
              continue
              ;;

            7)

              if [ "${generatedFileForServerProduct}" = "false" ]
                then
                debugMode "DB INS Server" "${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/DBInstances/${line}_instances.txt" ""
                checkFile ${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/DBInstances/${line}_instances.txt
                eval serverInstance="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/DBInstances/${line}_instances.txt"
                generatedFileForServerProduct=true
                continue
                #file for server products has been created
              fi

              if [ "${line}" = "INSTANCE_PER_SERVER_END" ]
              then
                  continueFlag=false
                  generatedFileForServerProduct=false
                  continue
              else
                  echo "${line}" >> ${serverInstance}
                  continue
              fi
              ;;
              8)
                debugMode "CC servers" ""
                if [ "${line}" = "CC_SERVER_END" ]
                  then
                  continueFlag=false
                  paramToHandle=$((paramToHandle+1))
                else
                  debugMode "CC_ARRAY" "${CC_ARRAY}"
                  echo "${line}" >> ${CC_ARRAY}
                  debugMode "CC_ARRAY_FILE" "${line}"
                  _ccArray[${_ccIndex}]=${line}
                  debugMode "CC_ARRAY" "${_ccArray[${_ccIndex}]}"
                  debugMode "CC_INDEX" "${_ccIndex}"
                  _ccIndex=$((_ccIndex+1))
                  debugMode "_ccIndex" "${_ccIndex}"
                fi
                i=1
                #initialize boolean array
                while [ ${i} -lt ${_ccIndex} ]
                do
                  debugMode "_ccBooleanArray[${i}]" "true"
                  _ccBooleanArray[${i}]="true"
                  i=$((i+1))
                done
                continue
                ;;

              9)
                _toolServer=${line}
                debugMode "_toolServer" "${_toolServer}"
                continueFlag=false
                paramToHandle=$((paramToHandle+1))
                continue
              ;;
          esac

        fi


        if [ "${line}" = "PROJECT_NAME_START" ]
          then
            continueFlag=true
            continue
        elif [ "${line}" = "PROJECT_DL_START" ]
          then
            continueFlag=true
            continue
        elif [ "${line}" = "PROJECT_ENSIGHT_DB_PARAM_START" ]
          then
            continueFlag=true
            continue
        elif [ "${line}" = "INT_SERVERS_LIST_START" ]
          then
            continueFlag=true
            continue
        elif [ "${line}" = "PRODUCTS_PER_SERVER_START" ]
          then
            continueFlag=true
            continue
        elif [ "${line}" = "PRODUCTS_PER_SERVER_FINISH" ]
          then
            paramToHandle=$((paramToHandle+1))
            continue
        elif [ "${line}" = "DB_SERVERS_LIST_START" ]
          then
            continueFlag=true
            _DBIndex=1
            continue
        elif [ "${line}" = "INSTANCE_PER_SERVER_START" ]
          then
            continueFlag=true
            continue
        elif [ "${line}" = "INSTANCE_PER_SERVER_FINISH" ]
          then
          paramToHandle=$((paramToHandle+1))
            continue

        elif [ "${line}" = "CC_SERVER_START" ]
          then
          debugMode "CC_SERVER_START case" ""
          continueFlag=true
          continue

        elif [ "${line}" = "TOOL_SERVER_START" ]
          then
          continueFlag=true
          continue
        else
              debugMode "else" ""
          fi
      index=$((index+1))
    done < "${PROJECT_DEFINITION}"
}

function buildStructureFile
{
  echo "General" >> "${PROJECT_DEFINITION}"
  echo "" >> "${PROJECT_DEFINITION}"
  debugMode "@@@function@@@" "buildStructureFile"
  index=1
  while read line
    do
      debugMode "line & ${index}" "${line}"
      if [ "${_projectNameParameters}" = "true" ]
        then
        _projectNameFromAutamaticDefinition="${line}"
        _projectNameParameters="false"
        echo "PROJECT_NAME_START" >> "${PROJECT_DEFINITION}"
        echo "${_projectNameFromAutamaticDefinition}" >> "${PROJECT_DEFINITION}"
        echo "PROJECT_NAME_END" >> "${PROJECT_DEFINITION}"
        echo "" >> "${PROJECT_DEFINITION}"
        continue
      fi

      if [ "${_projectDLParameters}" = "true" ]
        then
        _projectDLFromAutamaticDefinition="${line}"
        _projectDLParameters="false"
        echo "PROJECT_DL_START" >> "${PROJECT_DEFINITION}"
        echo "${_projectDLFromAutamaticDefinition}" >> "${PROJECT_DEFINITION}"
        echo "PROJECT_DL_END" >> "${PROJECT_DEFINITION}"
        echo "" >> "${PROJECT_DEFINITION}"
        continue
      fi

      if [ "${_dbEnsightParameters}" = "true" ]
        then
          _dbEnsightParametersFromAutomaticDefinition="${line}"
          _dbEnsightParameters="false"
          echo "PROJECT_ENSIGHT_DB_PARAM_START" >> "${PROJECT_DEFINITION}"
          echo "${_dbEnsightParametersFromAutomaticDefinition}" >> "${PROJECT_DEFINITION}"
          echo "PROJECT_ENSIGHT_DB_PARAM_END" >> "${PROJECT_DEFINITION}"
          echo "" >> "${PROJECT_DEFINITION}"
          continue
      fi
      if [ "${_queryParameters}" = "true" ]
        then
          _integrationAccountsAndServersQueryFromAutomaticDefinition="${line}"
          _queryParameters="false"
        continue
      fi
      if [ "${_queryDBParameters}" = "true" ]
        then
          _InstancesQueryFromAutomaticDefinition="${line}"
          _queryDBParameters="false"
        continue
      fi
      if [ "${_toolServerParameters}" = "true" ]
        then
          _toolServerFromAutomaticDefinition="${line}"
          _toolServerParameters="false"
      fi
      if [ "${_CCNameParameters}" = "true" ]
        then
          if [ ! "${line}" = "CC_SERVER_END"  ]
            then
              echo "${line}" >> "${PROJECT_DEFINITION}"
              continue
          else
            echo "CC_SERVER_END" >> "${PROJECT_DEFINITION}"
            echo "" >> "${PROJECT_DEFINITION}"
            echo "TOOL_SERVER_START" >> "${PROJECT_DEFINITION}"
            echo "${_toolServerFromAutomaticDefinition}" >> "${PROJECT_DEFINITION}"
            echo "TOOL_SERVER_END" >> "${PROJECT_DEFINITION}"
            _CCNameParameters="false"
          fi
      fi

      if [ "${line}" = "PROJECT_NAME_START" ]
        then
        _projectDLParameters="true"
        continue
      elif [ "${line}" = "PROJECT_DL_START" ]
        then
        _projectDLParameters="true"
        continue
      elif [ "${line}" = "PROJECT_ENSIGHT_DB_PARAM_START" ]
        then
          _dbEnsightParameters="true";
          continue
      elif [ "${line}" = "ACCOUNT_AND_SERVERS_QUERY_START" ]
        then
          _queryParameters="true"
          continue
      elif [ "${line}" = "DB_INSTANCES_QUERY_START" ]
        then
          _queryDBParameters="true"
          continue
      elif [ "${line}" = "TOOL_SERVER_START" ]
          then
          _toolServerParameters="true"
          continue

      #integration servers
      elif [ "${line}" = "TOOL_SERVER_END" ]
          then
          echo "INT Servers" >> "${PROJECT_DEFINITION}"
          echo "INT_SERVERS_LIST_START" >> "${PROJECT_DEFINITION}"

          getServerIntegreationFromDB
          echo "INT_SERVERS_LIST_END" >> "${PROJECT_DEFINITION}"
          echo "" >> "${PROJECT_DEFINITION}"

          checkProdutsFilePerMachine
          echo "" >> "${PROJECT_DEFINITION}"
          echo "PRODUCTS_PER_SERVER_FINISH" >> "${PROJECT_DEFINITION}"
          #echo "INT_SERVERS_LIST_START" >> "${PROJECT_DEFINITION}"
          echo "DB_SERVERS_LIST_START" >> "${PROJECT_DEFINITION}"
          checkDBServersFromDB
          getPureDBArray
          echo "DB_SERVERS_LIST_END" >> "${PROJECT_DEFINITION}"
          getInstacesPerServer

          continue
          ##CC case

      elif [ "${line}" = "CC_SERVER_START" ]
          then
          echo "" >> "${PROJECT_DEFINITION}"
          echo "${line}" >> "${PROJECT_DEFINITION}"
          _CCNameParameters="true"
          continue
      else
          debugMode "empty line" ""

      fi
      index=$((index+1))
    done < "${AUTOMATIC_RUNNING_DEFINITION}"

}

function checkDBServersFromDB
{
  debugMode "@@@function@@@" "checkDBServersFromDB"
  debugMode "_InstancesQueryFromAutomaticDefinition" "${_InstancesQueryFromAutomaticDefinition}"
  debugMode "_dbEnsightParametersFromAutomaticDefinition" "${_dbEnsightParametersFromAutomaticDefinition}"
queryForServersDB=`sqlplus ${_dbEnsightParametersFromAutomaticDefinition}   << EOF
  ${_InstancesQueryFromAutomaticDefinition};
  exit;
  EOF`
  debugMode "queryForServersDB" "${queryForServersDB}"
  checkFile ${TEMP_FILE}
  echo "${queryForServersDB}" > ${TEMP_FILE}
  instancesTemp=`grep @ ${TEMP_FILE} | sed 's/.*@//' | cut -d "<" -f 1| grep ZIG`
  debugMode "instancesTemp" "${instancesTemp}"
  for i in $instancesTemp
  do
    _instancesArrayTemp[${_indexInstancesArrayTemp}]="${i}"
    debugMode "_insArrTemp[${_indexInstancesArrayTemp}]" "${_instancesArrayTemp[${_indexInstancesArrayTemp}]}"
    _DBArrayTemp[${_indexDBArrayTemp}]=`grep "$i:" /oravl01/oracle/.env_ora_host | cut -d ":" -f 2`
    debugMode "_DBArrayTemp[${_indexDBArrayTemp}]" "${_DBArrayTemp[${_indexDBArrayTemp}]}"
    _indexDBArrayTemp=$((_indexDBArrayTemp+1))
    _indexInstancesArrayTemp=$((_indexInstancesArrayTemp+1))
  done

}

function getPureDBArray
{
  debugMode "@@@function@@@" "  getPureDBArray"
  debugMode "_indexDBArrayTemp" "${_indexDBArrayTemp}"
  debugMode "_DBIndex" "    ${_DBIndex}"

  if [[ ${_DBIndex} -eq 1 ]]
    then
    debugMode "implementation" ""
    _DBArray[${_DBIndex}]=${_DBArrayTemp[1]}
    debugMode "_DBArray[${_DBIndex}]" " ${_DBArray[${_DBIndex}]}"
    _DBIndex=$((_DBIndex+1))
    debugMode "_DBIndex" "  ${_DBIndex}"
  fi

  i=1
  while [[ ${i} -lt $((_indexDBArrayTemp)) ]]
    do

      debugMode "_DBArray[${_DBIndex}]" " ${_DBArray[$((_DBIndex-1))]}"
      debugMode "_DBArrayTemp[${i}]" " ${_DBArrayTemp[${i}]}"


      j=1
      #loop on DB array
      while [ ${j} -lt ${_DBIndex} ]
      do

          if [ "${_DBArray[${j}]}" = "${_DBArrayTemp[${i}]}" ]
            then
            break
          else
            if [ ${j} -eq $((_DBIndex-1)) ]
              then
                if [ "${_DBArray[${j}]}" = "${_DBArrayTemp[${i}]}" ]
                  then
                  break
                else
                  debugMode "DB array implementation" ""
                  _DBArray[${_DBIndex}]="${_DBArrayTemp[${i}]}"
                  _DBIndex=$((_DBIndex+1))
                fi
            fi
          fi

        j=$((j+1))
      done

    i=$((i+1))
  done

  debugMode "DB Array after implementation" ""
  i=1
  while [ ${i} -lt ${_DBIndex} ]
    do
      debugMode "_DBArray[${i}]" "${_DBArray[${i}]}"
      echo "${_DBArray[${i}]}" >> "${PROJECT_DEFINITION}"
      i=$((i+1))
  done
}


function getInstacesPerServer
{
  TEMP_FILE2="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/TEMP_FILE2"
  firstTime="true"
  j=1
  while [ ${j} -lt ${_DBIndex} ]
  do
    debugMode "`cat ${TEMP_FILE2}`" ""
    checkFile "${TEMP_FILE2}"


    echo "INSTANCE_PER_SERVER_START" >> "${PROJECT_DEFINITION}"
    echo "${_DBArray[${j}]}" >> "${PROJECT_DEFINITION}"

      i=1
      while [ ${i} -lt ${_indexInstancesArrayTemp} ]
        do
          if [ "${firstTime}" = "true" ]
            then
              echo "${_instancesArrayTemp[1]}" >> "${TEMP_FILE2}"
              echo "${_instancesArrayTemp[1]}" >> "${PROJECT_DEFINITION}"
              firstTime="false"
          fi

            checkFile "${TEMP_FILE}"
            debugMode "_DBArrayTemp[${i}]" "${_DBArrayTemp[${i}]}"
            if [ "${_DBArrayTemp[${i}]}" = "${_DBArray[${j}]}" ]
              then

                  echo "`grep ${_instancesArrayTemp[${i}]} ${TEMP_FILE2}`" >> ${TEMP_FILE}
                  debugMode "check if instance exists !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" "`cat ${TEMP_FILE}`"
                  fileSize=`ls -l ${TEMP_FILE} | awk '{ print $5}'`
                  debugMode "`ls -l ${TEMP_FILE} | awk '{ print $5}'`" ""
                  if [ ${fileSize} -lt 2 ]
                    then
                    debugMode "Adding new instance condition !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" ""
                    echo "${_instancesArrayTemp[${i}]}" >> "${TEMP_FILE2}"
                    echo "${_instancesArrayTemp[${i}]}" >> "${PROJECT_DEFINITION}"
                  else
                    debugMode  "_instancesArrayTemp[${i}]" "${_instancesArrayTemp[${i}]}"
                    debugMode "TEMP_FILE2 exist the above instance" ""
                  fi

            else
              debugMode "There is no match between server and instance" ""
            fi
          i=$((i+1))
      done
      echo "INSTANCE_PER_SERVER_END" >> "${PROJECT_DEFINITION}"
   j=$((j+1))
  done
  echo "INSTANCE_PER_SERVER_FINISH" >> "${PROJECT_DEFINITION}"
}



#get pure list for INT servers
function getServerIntegreationFromDB
{
  checkFile ${TEMP_FILE}
  debugMode "@@@function@@@" "getServerIntegreationFromDB"
  debugMode "_dbEnsightParametersFromAutomaticDefinition" "${_dbEnsightParametersFromAutomaticDefinition}"
  debugMode "_integrationAccountsAndServersQueryFromAutomaticDefinition" "${_integrationAccountsAndServersQueryFromAutomaticDefinition}"
serverIntegrationAndAccountList=`sqlplus ${_dbEnsightParametersFromAutomaticDefinition}   << EOF
	SET PAGES 400
	${_integrationAccountsAndServersQueryFromAutomaticDefinition};
	exit;
EOF`

	debugMode "all parameters define here" "\n${serverIntegrationAndAccountList}"
	echo "${serverIntegrationAndAccountList}" > ${TEMP_FILE}
	length=`cat ${TEMP_FILE} | wc -l`
 	debugMode "length" "${length}"

 	#get servers from the file
	while read line
	do
		debugMode "line" "        ${line}"
		echo "${line}" > "${TEMP_ROW}"
		#tmpGrepQuery=${projectLowerCase}|cache
		accountAndServer=`grep -E 'zig|cache'  ${TEMP_ROW}`
		debugMode "account server" "${accountAndServer}"
		#if the row contains valid account
		if [ ! -z "${accountAndServer}" ]
			then

				tmpServer=`echo ${line} | cut -f2 -d"@"`
				debugMode "tmpServer" "${tmpServer}"

				if [ ! -z "${tmpServer}" ]
				then
											#let's check if we have this server on our array

											if [ ${_integrationServersLastIndex} -eq 0 ]
											then
												debugMode "new server was added to the array"	""
												_integrationServersLastIndex=$((_integrationServersLastIndex+1))
												_integrationServersList[$((_integrationServersLastIndex))]="${tmpServer}"

                        if [ "${_integrationServersList[$((_integrationServersLastIndex))]}" != "${_toolServerFromAutomaticDefinition}" ]
                          then
                          echo "${_integrationServersList[$((_integrationServersLastIndex))]}" >> ${PROJECT_DEFINITION}
                        fi



											fi
											j=1
											while [[ ${j} -lt $((_integrationServersLastIndex+1)) ]]
											do
												if [ "${_integrationServersList[${j}]}" = "${tmpServer}" ]
													then
													break
												fi
												if [[ "${j}" = "${_integrationServersLastIndex}" ]]
												then

													if [	"${_integrationServersList[${j}]}" = "${tmpServer}" ]
														then
														break
													else
														debugMode "new server was added to the array"	""
														_integrationServersLastIndex=$((_integrationServersLastIndex+1))
														_integrationServersList[${_integrationServersLastIndex}]="${tmpServer}"
                            if [ "${_integrationServersList[$((_integrationServersLastIndex))]}" != "${_toolServerFromAutomaticDefinition}" ]
                              then
                              echo "${_integrationServersList[$((_integrationServersLastIndex))]}" >> ${PROJECT_DEFINITION}
                            fi

													fi
												fi
												j=$((j+1))
											done
						else
							continue
						fi
		else
			continue
		fi
	done < "${TEMP_FILE}"

  _integrationServersLastIndex=$((_integrationServersLastIndex+1))
  _integrationServersList[${_integrationServersLastIndex}]="${_toolServerFromAutomaticDefinition}"
}

#Calling machine parser from DB in order to acheive pure data of the products per server
function checkProdutsFilePerMachine
{
 debugMode "@@@function@@@" "checkProdutsFilePerMachine"
 #let's generate the file for each server its product list
 j=1
 while [[ ${j} -lt $((_integrationServersLastIndex+1)) ]]
 do
   debugMode "Checking products for server:" "${_integrationServersList[${j}]}"
   echo "PRODUCTS_PER_SERVER_START" >> "${PROJECT_DEFINITION}"
   echo "${_integrationServersList[${j}]}" >> "${PROJECT_DEFINITION}"
   parsingMachineFromSqlQuery "${_dbEnsightParametersFromAutomaticDefinition}" "SELECT DISTINCT product FROM ensdata WHERE user_host LIKE" "${_integrationServersList[${j}]}" "3"
   echo "PRODUCTS_PER_SERVER_END" >> "${PROJECT_DEFINITION}"
 j=$((j+1))
 done
}

function parsingMachineFromSqlQuery
{
  debugMode "@@@function@@@" "parsingMachineFromSqlQuery"
  DB_CONNECTION=$1
  DB_QUERY=$2
  ADDITIONAL_PARAM=$3
  OPTION=$4

  debugMode "DB_CONNECTION" "${DB_CONNECTION}"
  debugMode "DB_QUERY" "${DB_QUERY}"
  debugMode "ADDITIONAL_PARAM" "${ADDITIONAL_PARAM}"
  debugMode "OPTION" "${OPTION}"


  DBData=""

  case "${OPTION}" in
  	"2")echo "option 2"
  			;;
  	"3")
  			DBData=`sqlplus ${DB_CONNECTION}   << EOF
  			SET PAGES 400
  			${DB_QUERY} '%${ADDITIONAL_PARAM}%';
  			exit;
  			EOF`
  			;;

  esac

  debugMode "DBData" "${DBData}"

#  pureData=""
#  eval pureData="${HOME}/oriav/tmp/AutoServerDiagram/PURE_PRODUCTS_PER_SERVER_${ADDITIONAL_PARAM}.txt"
#  checkFile "${pureData}"

#  dataBaseProductsQuery=""
  #this files get the information from the DB per each server
#  eval dataBaseProducts="${HOME}/oriav/tmp/AutoServerDiagram/DB_PRODUCTS_QUERY_${ADDITIONAL_PARAM}.txt"
#  checkFile "${dataBaseProducts}"
#  echo "${DBData}" > "${dataBaseProducts}"

  checkFile "${TEMP_FILE}"
  echo "${DBData}" > "${TEMP_FILE}"


  lineNumber=13
  index=1
  	while read line
  		do
  			debugMode "line & ${index}" "		${line}"
  			echo "${line}" > "${TEMP_ROW}"
  			if [ "${index}" -gt "${lineNumber}" ]
  				then
  				stopCondition=`cat ${TEMP_ROW}|grep "SQL> Disconnected"`
  				#if we aren't in row that starts with "SQL> Disconnected"
          if [ -z "${stopCondition}" ]
  				then
  					debugMode "pure products per server " "`cat ${TEMP_ROW}`"
  					#echo "`cat ${TEMP_ROW}`" >> ${pureData}
            echo "`cat ${TEMP_ROW}`" >> "${PROJECT_DEFINITION}"
  				else
  					debugMode "Products List: " "Stop condition"
  					#we reached to the sql line
  					break
  				fi
  			fi
  			index=$((index+1))
  		done < "${TEMP_FILE}"
  #	#We generated file with last line which is empty
}






function corrcetDBFileRowsSize
{
  debugMode "@@@function@@@" "corrcetDBFileRowsSize"
  j=1
  while [[ ${j} -lt $((_DBIndex)) ]]
  do
    debugMode "_DBArray[${j}]" "${_DBArray[${j}]}"
    fileName="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/DBInstances/${_DBArray[${j}]}_instances.txt"
    debugMode "fileName"  "${fileName}"
    numberOfRows=`cat ${fileName} | wc -l`
    debugMode "numberOfRows"  "${numberOfRows}"
    while [[ "${numberOfRows}" -lt "${DB_ROWS}" ]]
      do
        echo "" >> ${fileName}
        numberOfRows=`cat ${fileName} | wc -l`
        debugMode "numberOfRows"  "${numberOfRows}"
      done
    j=$((j+1))
  done
}

function corrcetIntegrationFileRowsSize
{
  debugMode "@@@function@@@" "corrcetINTFileRowsSize"
  numberOfRows=""
  fileName=""
  j=1
  while [[ ${j} -lt $((_intIndex)) ]]
  do
    fileName="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/Products/${_intArray[${j}]}_products.txt"
    debugMode "fileName"  "${fileName}"
    numberOfRows=`cat ${fileName} | wc -l`
    debugMode "numberOfRows"  "${numberOfRows}"
    while [[ "${numberOfRows}" -lt "${INT_ROWS}" ]]
      do
        echo "" >> ${fileName}
        numberOfRows=`cat ${fileName} | wc -l`
        debugMode "numberOfRows"  "${numberOfRows}"
      done
    j=$((j+1))
  done


  fileName="${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/Products/${_toolServer}_products.txt"
  debugMode "fileName"  "${fileName}"
  numberOfRows=`cat ${fileName} | wc -l`
  debugMode "numberOfRows"  "${numberOfRows}"
  while [[ "${numberOfRows}" -lt "${INT_ROWS}" ]]
    do
      echo "" >> ${fileName}
      numberOfRows=`cat ${fileName} | wc -l`
      debugMode "numberOfRows"  "${numberOfRows}"
    done

}










#function getDBServersNames
# {
#  debugMode "@@@function@@@" "getDBServersNames"
#  echo "%%%% LIST OF DB SERVERS - START %%%%" >> ${INPUT_FILE_FOR_GENERATING_SCHEMA}
#  DBServerList=${HOME}/oriav/tmp/AutoServerDiagram/PURE_DB_SERVERS.txt
#  index=1
#  while read line
#    do
#      debugMode "line & ${index}" "		${line}"
#      _DBServersLastIndex=$((_DBServersLastIndex+1))
#      _DBServersList[${_DBServersLastIndex}]="${line}"
#      echo "_DBServersList[${_DBServersLastIndex}]" >> ${INPUT_FILE_FOR_GENERATING_SCHEMA}
#      index=$((index+1))
#    done < "${DBServerList}"
#    printArray DB false

#    echo "%%%% LIST OF DB SERVERS - END %%%%" >> ${INPUT_FILE_FOR_GENERATING_SCHEMA}
#}







function checkDL
{
  debugMode "@@@function@@@" "checkDL"
	if [ ${RUN_MODE} = "debug" ]
  then
  		#TO_MAIL="ori.aviv@amdocs.com"
  		TO_MAIL="${_projectDL}"
  else
  		#_TO_MAIL="ZIGInfraIntegration@int.amdocs.com"
  		TO_MAIL="${_projectDL}"
      #TO_MAIL="ori.aviv@amdocs.com"
  fi

  if [ $# -eq 1 ]
    then
    TO_MAIL="${1}"
  fi
}

#function checkToolServerInTheArray
# {
#  debugMode "@@@function@@@" "checkToolServerInTheArray"
#  tmpServer=$(<${TOOLS_SERVER_FILE})
#  tempIndex=""
#  i=1
#  while [ "${i}" -lt "${_integrationServersLastIndex}" ]
#  do

#      if [ "${_integrationServersList[${i}]}" = "${tmpServer}" ]
#        then
#          tempIndex=${i}
#          while [ "${i}" -lt "${_integrationServersLastIndex}" ]
#          do
#            _integrationServersList[${i}]="${_integrationServersList[$((i+1))]}"
#            i=$((i+1))
#          done
#      fi
#      i=$((i+1))
#  done
#  _integrationServersLastIndex=$((_integrationServersLastIndex-1))
#  printArray integration true
#}

function readHTMLToVariable
{
  debugMode "@@@function@@@" "readHTMLToVariable"
	while read line
	do
    debugMode "line" "${line}"
		_htmlContent=$_htmlContent${line}
	done <"${HTML_FILE}"
	#echo "_htmlContent 		\n${_htmlContent}"
}


function checkInstanceStatus
{
  checkFile ${TEMP_FILE}
  instance=$1
  echo "`tnsping ${instance}`" > ${TEMP_FILE}
  echo "`grep OK ${TEMP_FILE}`" > ${TEMP_ROW}
  debugMode "instance is up" "`cat ${TEMP_ROW}`"
  if [ ! -z "`cat ${TEMP_ROW}`" ]
    then
      flagStatus="UP"
    else
      flagStatus="DOWN"
    fi
}


function generateHTMLFile
{
  debugMode "@@@function@@@" "generateHTMLTable"
  debugMode "generating html file" ""
  debugMode "HTML_FILE" "${HTML_FILE}"

  WIDTH_COL=120
  IMAGE_HEIGHT=100
  IMAGE_WIDTH=auto

  WIDTH_COL_DB=120
  IMAGE_HEIGHT_DB=100
  IMAGE_WIDTH_DB=auto

  FONT_SERVER_FACE="Bradley Hand ITC"
  FONT_HEADER_FACE="Bradley Hand ITC"
  FONT_HEADER_SIZE="6"
  FONT_SERVER_SIZE="4"
  FONT_PRODUCT_SIZE="3"
  FONT_INSTANCE_SIZE="1"
  echo "<html>" >> "${HTML_FILE}"
  echo "<head>" >> ${HTML_FILE}
  echo "<h3><font face=\"${FONT_HEADER_FACE}\" size=\"${FONT_HEADER_SIZE}\"> <center>Auto Servers Diagram - ${RUNNING_STATUS} mode</center></font></h3>" >> ${HTML_FILE}
  echo "</head>" >> ${HTML_FILE}
  echo "<body>" >> ${HTML_FILE}

  ccEqualToIntegration="false"

  #INT servers
  echo "<ul>" >> ${HTML_FILE}
  echo "<li><font face=\"Bradley Hand ITC\" size=\"4\"><i><u>Infra INT Servers list and its appropriate products</u></i></font></li>" >> ${HTML_FILE}
  echo "</ul>" >> ${HTML_FILE}

  echo "<table border=\"0\" align=\"center\">" >> ${HTML_FILE}


  echo "<tr>" >> ${HTML_FILE}
  i=1
  debugMode "_intIndex" "${_intIndex}"

  while [ ${i} -lt $((_intIndex)) ]
  do
    #echo "${i}"
    #echo "${_intIndex}"
    echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center>${_intArray[${i}]}</center></font></td>" >> ${HTML_FILE}
    i=$((i+1))
  done

  echo "</tr>" >> ${HTML_FILE}
  echo "<tr>" >> ${HTML_FILE}
  i=1
  while [ ${i} -lt $((_intIndex)) ]
  do
    k=1
    debugMode "_ccIndex" "${_ccIndex}"
    while [ ${k} -lt $((_ccIndex))  ]
    do




        if [ "${_intArray[${i}]}" = "${_ccArray[${k}]}" ]
          then
          ccEqualToIntegration="true"
          _ccBooleanArray[${k}]="false"




        fi
        k=$((k+1))
    done


    debugMode "ccEqualToIntegration" "${ccEqualToIntegration}"
    if [ "${ccEqualToIntegration}" = "true" ]
        then
        echo "<td width=\"${WIDTH_COL}\"><center><img src=\"${IMAGE_CC_SERVER_URL}\" height=\"${IMAGE_HEIGHT}\" width=\"${IMAGE_WIDTH}\"></center></td>" >> ${HTML_FILE}
        ccEqualToIntegration="false"
    else
        echo "<td width=\"${WIDTH_COL}\"><center><img src=\"${IMAGE_SERVER_URL}\" height=\"${IMAGE_HEIGHT}\" width=\"${IMAGE_WIDTH}\"></center></td>" >> ${HTML_FILE}
    fi
    i=$((i+1))
  done
  echo "</tr>" >> ${HTML_FILE}

  i=1
  while [ ${i} -lt 5 ]
  do
            j=1
            echo "<tr>" >> ${HTML_FILE}
            while [ ${j} -lt $((_intIndex)) ]
            do
                echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_PRODUCT_SIZE}\"><center>`head -${i} ${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/Products/${_intArray[${j}]}_products.txt | tail -1`</center></font></td>" >> ${HTML_FILE}
              j=$((j+1))
            done
            echo "</tr>" >> ${HTML_FILE}
    i=$((i+1))
  done

  echo "</table>" >> ${HTML_FILE}












  #DB servers
  echo "<ul>" >> ${HTML_FILE}
  echo "<li><font face="Bradley Hand ITC" size="4"><i><u>Infra DB Servers list and its appropriate instances</u></i></font></li>" >> ${HTML_FILE}
  echo "</ul>" >> ${HTML_FILE}
  echo "<table border=\"0\" align=\"center\">" >> ${HTML_FILE}
  echo "<tr>" >> ${HTML_FILE}
  i=1
  debugMode "_DBIndex" "${_DBIndex}"
  while [ ${i} -lt $((_DBIndex)) ]
  do


    #echo "${_DBArray[${i}]}"
    echo "<td width=\"${WIDTH_COL_DB}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center>${_DBArray[${i}]}</center></font></td>" >> ${HTML_FILE}
    i=$((i+1))
  done
  echo "</tr>" >> ${HTML_FILE}

  echo "<tr>" >> ${HTML_FILE}
  i=1
  while [ ${i} -lt $((_DBIndex)) ]
  do
    echo "<td width=\"${WIDTH_COL_DB}\"><center><img src=\"${IMAGE_DB_SERVER_URL}\" height=\"${IMAGE_HEIGHT_DB}\" width=\"${IMAGE_WIDTH_DB}\"></center></td>" >> ${HTML_FILE}
    i=$((i+1))
  done
  echo "</tr>" >> ${HTML_FILE}

  i=1




  while [ ${i} -lt 25 ]
  #while [ ${i} -lt $((_DBIndex)) ]
  do
    echo "<tr>" >> ${HTML_FILE}

            j=1
            #echo "<tr>" >> ${HTML_FILE}
            #while [ ${j} -lt 25 ]
            while [ ${j} -lt $((_DBIndex)) ]
            do
                debugMode "i    " "        ${i}"
                debugMode "j    " "        ${j}"
                debugMode "_DBArray[${j}]" "${_DBArray[${j}]}"


                tempInstance=`head -${i} ${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/DBInstances/${_DBArray[${j}]}_instances.txt | tail -1`


                debugMode "tempInstance" "${tempInstance}"
                if [ ! -z "${tempInstance}" ]
                  then

                flagStatus="down"
                debugMode "tempInstance" "${tempInstance}"
                checkInstanceStatus ${tempInstance} flagStatus
                debugMode "flagStatus" "${flagStatus}"



                  if [ "${flagStatus}" = "UP" ]
                    then
                    echo "<td width=\"${WIDTH_COL_DB}\"><font color=\"green\" face=\"${FONT_SERVER_FACE}\" size=\"${FONT_INSTANCE_SIZE}\"><center>${tempInstance}</center></font></td>" >> ${HTML_FILE}
                  else
                    echo "<td width=\"${WIDTH_COL_DB}\"><font color=\"red\" face=\"${FONT_SERVER_FACE}\" size=\"${FONT_INSTANCE_SIZE}\"><center>${tempInstance}</center></font></td>" >> ${HTML_FILE}
                  fi


                else
                  echo "<td width=\"${WIDTH_COL_DB}\"><font color=\"green\" face=\"${FONT_SERVER_FACE}\" size=\"${FONT_INSTANCE_SIZE}\"><center></center></font></td>" >> ${HTML_FILE}
                  debugMode "parameter is null" ""
                fi


              j=$((j+1))
            done

            echo "</tr>" >> ${HTML_FILE}
    i=$((i+1))
  done



  echo "</table>" >> ${HTML_FILE}





  #Tool servers
  echo "<ul>" >> ${HTML_FILE}
  echo "<li><font face="Bradley Hand ITC" size="4"><i><u><b>Infra Server Tool</b></u></i></font></li>"  >> ${HTML_FILE}
  echo "</ul>" >> ${HTML_FILE}

  echo "<table border=\"0\" align=\"center\">" >> ${HTML_FILE}

  echo "<tr>" >> ${HTML_FILE}
  i=1
  debugMode "_intIndex" "${_intIndex}"
  while [ "${i}" -lt "$((_intIndex))" ]
    do
      if [ "${i}" -gt "1" ]
        then
          echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center></center></font></td>" >> ${HTML_FILE}
      else
          echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center>"${_toolServer}"</center></font></td>" >> ${HTML_FILE}
      fi
      i=$((i+1))
    done
  echo "</tr>" >> ${HTML_FILE}



  i=1
  echo "<tr>" >> ${HTML_FILE}
  while [ ${i} -lt $((_intIndex)) ]
    do
      if [ "${i}" -gt "1" ]
        then
          echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center></center></font></td>" >> ${HTML_FILE}
      else
          echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center><img src=\"${IMAGE_SERVER_URL}\" height=\"${IMAGE_HEIGHT}\" width=\"${IMAGE_WIDTH}\"></center></font></td>" >> ${HTML_FILE}
      fi
      i=$((i+1))
    done
  echo "</tr>" >> ${HTML_FILE}


    j=1
    while [ "${j}" -lt "5" ]
    do
      i=1
      echo "<tr>" >> ${HTML_FILE}
      while [ ${i} -lt $((_intIndex)) ]
        do

          if [ "${i}" -gt "1" ]
            then
              echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center></center></font></td>" >> ${HTML_FILE}
          else
              debugMode "i" "${i}"
              debugMode "j" "${j}"
              debugMode "Products" "`head -${j} ${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/Products/${_toolServer}_products.txt | tail -1`"
              echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center>`head -${j} ${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/Products/${_toolServer}_products.txt | tail -1`</center></font></td>" >> ${HTML_FILE}
          fi
          i=$((i+1))
      done
      echo "</tr>" >> ${HTML_FILE}
      j=$((j+1))
    done



  echo "</tr>" >> ${HTML_FILE}

  echo "</table>" >> ${HTML_FILE}



  #CC servers
  ccSection="false"
  i=1
  while [ ${i} -lt ${_ccIndex} ]
  do
    debugMode "_ccBooleanArray[${i}]" "${_ccBooleanArray[${i}]}"
    if [ "${_ccBooleanArray[${i}]}" = "true" ]
      then
      ccSection="true"
    fi
    i=$((i+1))
  done

  if [ "${ccSection}" = "true" ]
    then
    echo "<ul>" >> ${HTML_FILE}
    echo "<li><font face="Bradley Hand ITC" size="4"><i><u>Infra CC Servers list and its appropriate instances</u></i></font></li>" >> ${HTML_FILE}
    echo "</ul>" >> ${HTML_FILE}

    echo "<table border=\"0\" align=\"center\">" >> ${HTML_FILE}


    J=1
    while [ "${J}" -lt "$((_ccIndex))" ]
      do

        if [ "${_ccBooleanArray[${j}]}" = "true" ]
          then

          echo "<tr>" >> ${HTML_FILE}

          i=1
          while [ ${i} -lt ${_intIndex} ]
          do
              if [ "${i}" -gt "1" ]
                then
                  echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center></center></font></td>" >> ${HTML_FILE}
              else
                  echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center>"${_ccArray[${j}]}"</center></font></td>" >> ${HTML_FILE}
              fi
              i=$((i+1))
          done

          echo "</tr>" >> ${HTML_FILE}
        fi
      j=$((j+1))
    done






    i=1
    echo "<tr>" >> ${HTML_FILE}
    while [ ${i} -lt $((_intIndex)) ]
      do
        if [ "${i}" -gt "1" ]
          then
            echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center></center></font></td>" >> ${HTML_FILE}
        else
            echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center><img src=\"${IMAGE_CC_SERVER_URL}\" height=\"${IMAGE_HEIGHT}\" width=\"${IMAGE_WIDTH}\"></center></font></td>" >> ${HTML_FILE}
        fi
        i=$((i+1))
      done
    echo "</tr>" >> ${HTML_FILE}


  echo "</table>" >> ${HTML_FILE}




  fi









#          j=1
#          while [ "${j}" -lt "5" ]
#          do
#            i=1
#            echo "<tr>" >> ${HTML_FILE}
#            while [ ${i} -lt $((_intIndex)) ]
#              do

#                if [ "${i}" -gt "1" ]
#                  then
#                    echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center></center></font></td>" >> ${HTML_FILE}
#                else
#                    debugMode "i" "${i}"
#                    debugMode "j" "${j}"
#                    debugMode "Products" "`head -${j} ${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/Products/${_toolServer}_products.txt | tail -1`"
#                    echo "<td width=\"${WIDTH_COL}\"><font face=\"${FONT_SERVER_FACE}\" size=\"${FONT_SERVER_SIZE}\"><center>`head -${j} ${HOME}/oriav/Scripts/AutoServersDiagram_Ver2/tmp/Products/${_toolServer}_products.txt | tail -1`</center></font></td>" >> ${HTML_FILE}
#                fi
#                i=$((i+1))
#            done
#            echo "</tr>" >> ${HTML_FILE}
#            j=$((j+1))
#          done
#      echo "</tr>" >> ${HTML_FILE}






  echo "</body>" >> ${HTML_FILE}
	echo "</html>" >> ${HTML_FILE}


}



function sendMail
{
FROM_MAIL=${_projectDL}
debugMode "FROM_MAIL" ${FROM_MAIL}
debugMode "TO_MAIL" ${TO_MAIL}


/usr/lib/sendmail -t <<EOF
From:${FROM_MAIL}
To:${TO_MAIL}
Subject: ATT DVC Servers
Content-Type: text/html

`cat ${HTML_FILE}`

EOF
#${_htmlContent}

}


function debugMode
{
	paramToWrite=$1
	valueOfTheParam=$2
	if [ ${RUN_MODE} = "debug" ]
  	then
   	echo "${paramToWrite} 			${valueOfTheParam}"
  fi
	if [ ${RUN_MODE} = "log" ]
   	then
   	echo "${paramToWrite} 			${valueOfTheParam}" >> ${LOG_FILE}
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

function checkDirectory
{
  dirName=$1
  if [ ! -d ${dirName} ]
    then
    mkdir ${dirName}
  fi
}



##########   Main   ##########

preCondition
if [ "${RUNNING_STATUS}" = "manual" ]
  then
  debugMode "### manual mode ###" ""
  cp ${MANUAL_RUNNING_DEFINITION} ${PROJECT_DEFINITION}
  parserMachine
elif [ "${RUNNING_STATUS}" = "automatic" ]
  then
  debugMode "### automatic mode ###" ""
  buildStructureFile
  parserMachine
else
  echo "RUNNING_STATUS is ilegal"
  exit
fi

if [ $# -eq 3 ]
  then
  checkDL $3
else
  checkDL
fi


corrcetDBFileRowsSize
corrcetIntegrationFileRowsSize

generateHTMLFile
#echo "finish genrating the file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
readHTMLToVariable

sendMail

########	genrate global product array per machine	#########
#debugMode "genrate global product array per machine" "######"
#j=1
#while [[ ${j} -lt $((_integrationServersLastIndex+1)) ]]
#do
#	eval _productsPer${_integrationServersList[${j}]}=""
#	eval _productsLastIndexPer${_integrationServersList[${j}]}=""
#	debugMode "_productsPer${_integrationServersList[${j}]}" "	######"
#	debugMode "_productsLastIndexPer${_integrationServersList[${j}]}" "######"
#	j=$((j+1))
#done
########	genrate global product array per machine - END	###




########## Main-End ##########
