#!/usr/bin/ksh
#===============================================================
# Name : getSwpInfo
# Programmer: Andre Oliveira
# Date : 2016/08/11
# Purpose : Used to get information from a SWP
#
# Changes history:
#
# Date       | By           | Changes/New features
# -----------+--------------+-----------------------------------
# 2016/08/11 | Andreo       | Script Creation
#===============================================================

# Setting the properties of the script. The below values need to be changed according to the HFtool DB information of the account.
{
export INFRATOOLS_AMC_HOST="$HOST"
export INFRATOOLS_HOST="$(grep $LOGNAME /etc/passwd | cut -d ':' -f 6)"
export INFRATOOLS_CONFIG_DIR="${INFRATOOLS_HOST}/Amc-${INFRATOOLS_AMC_HOST}/config"
export INFRATOOLS_DB_CONFIG_FILE="${INFRATOOLS_CONFIG_DIR}/AmcRunSqlPIConList.xml"

export INFRATOOLS_DB_USER="$(grep User ${INFRATOOLS_DB_CONFIG_FILE} | sort -u | cut -d '>' -f 2 | cut -d '<' -f 1)"
export INFRATOOLS_DB_PASSWORD="$(grep Pass ${INFRATOOLS_DB_CONFIG_FILE} | sort -u | cut -d '>' -f 2 | cut -d '<' -f 1)"
export INFRATOOLS_DB_INSTANCE="$(grep Url ${INFRATOOLS_DB_CONFIG_FILE} | head -1 | cut -d '<' -f 2 | cut -d ':' -f 6)"

}

# Setting other variables and definitions used by the script
{
export TEMP_FILE_1="/tmp/deployHotfix_TEMP_FILE_1_$$.txt"
export TEMP_FILE_2="/tmp/deployHotfix_TEMP_FILE_2_$$.txt"

export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)
export WHITE=$(tput setaf 7)
export BRIGHT=$(tput bold)
export NORMAL=$(tput sgr0)
export UNDERLINE=$(tput smul)
}

# Functions that will be used on the script

getParameterFromIMTDB(){
    parameter=$1
    flow_id=$2
    sqlplus -s "${INFRATOOLS_DB_USER}/${INFRATOOLS_DB_PASSWORD}@${INFRATOOLS_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select distinct param_value
    from IMT_FLOW_INFO
    where param_name='${parameter}'
    and flow_id like '${flow_id}'
    order by 1 desc;
SQL
}

getParametersFromIMTDB(){
    parameter_name=$1
    swp_param_name_1=$2
    swp_param_value_1=$3
    swp_param_name_2=$4
    swp_param_value_2=$5
    sqlplus -s "${INFRATOOLS_DB_USER}/${INFRATOOLS_DB_PASSWORD}@${INFRATOOLS_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select * 
    from (select distinct a.${parameter_name}
    from IMT_FLOW_INFO a, IMT_FLOW_INFO b
    where 1=1
    and a.param_name='${swp_param_name_1}'
    and a.param_value like '${swp_param_value_1}'
    and a.flow_id=b.flow_id
    and b.param_name='${swp_param_name_2}'
    and b.param_value like '${swp_param_value_2}'
    order by 1 desc)
    where rownum < 20;
SQL
}

## This lists the contents of a file into a numbered UI, and return value of the selected option
listValues(){
    clear
    input_file=$1
    ouput_file=$2
    string=$3
    num=1
    while read line_from_file
    do
    printf "${NORMAL}%-6s${NORMAL}%s${NORMAL}\n" '('${num}') ' ${line_from_file}
    num=$((num+1))
    done < ${input_file}
    printf "--- Choose the desired ${string}: "
    read "value"
    printf "$(sed -n "${value}p" ${input_file})" > ${ouput_file}
}

# This functions remove the temporary files that were created
cleanTempFiles(){
    rm -f ${TEMP_FILE_1}
    rm -f ${TEMP_FILE_2}
}

######################################################
##           Main execution of the script           ##
######################################################

## Getting SWP Version
getParameterFromIMTDB "SWP_VERSION" "%" > ${TEMP_FILE_1}
perl -pi -e "s/^\n//" ${TEMP_FILE_1}
listValues ${TEMP_FILE_1} ${TEMP_FILE_2} "SWAP VERSION"
SWP_VERSION="$(cat ${TEMP_FILE_2})"

## Getting SWP Name
getParametersFromIMTDB "param_value" "SWP_NAME" "%" "SWP_VERSION" "${SWP_VERSION}"  > ${TEMP_FILE_1}
perl -pi -e "s/^\n//" ${TEMP_FILE_1}
listValues ${TEMP_FILE_1} ${TEMP_FILE_2} "SWAP NAME"
SWP_NAME="$(cat ${TEMP_FILE_2})"

## Getting Perforce Label
getParametersFromIMTDB "param_value" "PERFORCE_LABEL" "%" "SWP_VERSION" "${SWP_VERSION}"  > ${TEMP_FILE_1}
perl -pi -e "s/^\n//" ${TEMP_FILE_1}

if [[ $(cat ${TEMP_FILE_1} | wc -l ) -gt 1 ]]
then
    listValues ${TEMP_FILE_1} ${TEMP_FILE_2} "PERFORCE LABEL" 
else
    cat ${TEMP_FILE_1} > ${TEMP_FILE_2} 
fi
PERFORCE_LABEL="$(cat ${TEMP_FILE_2})"

## Getting Flow ID
getParametersFromIMTDB "flow_id" "PERFORCE_LABEL" "${PERFORCE_LABEL}" "SWP_VERSION" "${SWP_VERSION}"  > ${TEMP_FILE_1}
perl -pi -e "s/^\n//" ${TEMP_FILE_1}
FLOW_ID="$(cat ${TEMP_FILE_1})"

##### Getting Unix Side Builds Information
    getParameterFromIMTDB "ABP_PRODUCT_BUILD_NUM" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    ABP_PRODUCT_BUILD_NUM="$(cat ${TEMP_FILE_1})"

    getParameterFromIMTDB "ABP_STORAGE_NAME" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    ABP_STORAGE_NAME="$(cat ${TEMP_FILE_1})"

    getParameterFromIMTDB "AMSS_PRODUCT_BUILD_NUM" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    AMSS_PRODUCT_BUILD_NUM="$(cat ${TEMP_FILE_1})"

    getParameterFromIMTDB "AMSS_STORAGE_NAME" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    AMSS_STORAGE_NAME="$(cat ${TEMP_FILE_1})"

    getParameterFromIMTDB "CRM_PRODUCT_BUILD_NUM" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    CRM_PRODUCT_BUILD_NUM="$(cat ${TEMP_FILE_1})"

    getParameterFromIMTDB "CRM_STORAGE_NAME" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    CRM_STORAGE_NAME="$(cat ${TEMP_FILE_1})"

    getParameterFromIMTDB "OMS_PRODUCT_BUILD_NUM" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    OMS_PRODUCT_BUILD_NUM="$(cat ${TEMP_FILE_1})"

    getParameterFromIMTDB "OMS_STORAGE_NAME" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    OMS_STORAGE_NAME="$(cat ${TEMP_FILE_1})"


##### Getting DB Side Builds Information
    getParameterFromIMTDB "ABP_DB_PATCH_ID" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    ABP_DB_PATCH_ID="$(cat ${TEMP_FILE_1})"
    if [[ "X${ABP_DB_PATCH_ID}" == "X" ]]
    then
        ABP_DB_PATCH_ID="N/A"
    fi
    
    getParameterFromIMTDB "ABP_REF_DMP" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    ABP_REF_DMP="$(cat ${TEMP_FILE_1})"
    if [[ "X${ABP_REF_DMP}" == "X" ]]
    then
        ABP_REF_DMP="N/A"
    fi

    getParameterFromIMTDB "AMSS_DB_PATCH_ID" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    AMSS_DB_PATCH_ID="$(cat ${TEMP_FILE_1})"
    if [[ "X${AMSS_DB_PATCH_ID}" == "X" ]]
    then
        AMSS_DB_PATCH_ID="N/A"
    fi
    
    getParameterFromIMTDB "AMSS_REF_DMP" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    AMSS_REF_DMP="$(cat ${TEMP_FILE_1})"
    if [[ "X${AMSS_REF_DMP}" == "X" ]]
    then
        AMSS_REF_DMP="N/A"
    fi
    
    getParameterFromIMTDB "OMS_DB_PATCH_ID" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    OMS_DB_PATCH_ID="$(cat ${TEMP_FILE_1})"
    if [[ "X${OMS_DB_PATCH_ID}" == "X" ]]
    then
        OMS_DB_PATCH_ID="N/A"
    fi
    
    getParameterFromIMTDB "OMS_REF_DMP" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    OMS_REF_DMP="$(cat ${TEMP_FILE_1})"
    if [[ "X${OMS_REF_DMP}" == "X" ]]
    then
        OMS_REF_DMP="N/A"
    fi
    
    getParameterFromIMTDB "SE_DB_PATCH_ID" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    SE_DB_PATCH_ID="$(cat ${TEMP_FILE_1})"
    if [[ "X${SE_DB_PATCH_ID}" == "X" ]]
    then
        SE_DB_PATCH_ID="N/A"
    fi
    
    getParameterFromIMTDB "SE_REF_DMP" "${FLOW_ID}"  > ${TEMP_FILE_1}
    perl -pi -e "s/^\n//" ${TEMP_FILE_1}
    SE_REF_DMP="$(cat ${TEMP_FILE_1})"
    if [[ "X${SE_REF_DMP}" == "X" ]]
    then
        SE_REF_DMP="N/A"
    fi
    
clear
printf "\n"
printf "%-15s${BRIGHT}${UNDERLINE}%s${NORMAL}\n" "" "SWP Information"
printf "%-2s${NORMAL}%-12s${NORMAL}%s${NORMAL}%s${NORMAL}\n" "" "VERSION" " = " "${SWP_VERSION}"
printf "%-2s${NORMAL}%-12s${NORMAL}%s${NORMAL}%s${NORMAL}\n" "" "NAME"  " = " "${SWP_NAME}"
printf "%-2s${NORMAL}%-12s${NORMAL}%s${NORMAL}%s${NORMAL}\n" "" "LABEL"  " = " "${PERFORCE_LABEL}"
printf "\n"
printf "%-10s${BRIGHT}${GREEN}${UNDERLINE}%s${NORMAL}\n" "" "Unix Side Information"
printf "%-2s${GREEN}%-10s${GREEN}%-15s${GREEN}%s${NORMAL}\n" "" "Product" "Build Number" "Storage Name"
printf "%-2s${NORMAL}%-14s${NORMAL}%-10s${NORMAL}%s${NORMAL}\n" "" "ABP" "${ABP_PRODUCT_BUILD_NUM}" "${ABP_STORAGE_NAME}"
printf "%-2s${NORMAL}%-14s${NORMAL}%-10s${NORMAL}%s${NORMAL}\n" "" "AMSS" "${AMSS_PRODUCT_BUILD_NUM}" "${AMSS_STORAGE_NAME}"
printf "%-2s${NORMAL}%-14s${NORMAL}%-10s${NORMAL}%s${NORMAL}\n" "" "CRM" "${CRM_PRODUCT_BUILD_NUM}" "${CRM_STORAGE_NAME}"
printf "%-2s${NORMAL}%-14s${NORMAL}%-10s${NORMAL}%s${NORMAL}\n" "" "OMS" "${OMS_PRODUCT_BUILD_NUM}" "${OMS_STORAGE_NAME}"
printf "\n"
printf "%-10s${BRIGHT}${YELLOW}${UNDERLINE}%s${NORMAL}\n" "" "DB Side Information"
printf "%-2s${YELLOW}%-10s${YELLOW}%-15s${YELLOW}%s${NORMAL}\n" "" "Product" "Patch Number" "DMP Name"
printf "%-2s${NORMAL}%-14s${NORMAL}%-10s${NORMAL}%s${NORMAL}\n" "" "ABP" "${ABP_DB_PATCH_ID}" "${ABP_REF_DMP}"
printf "%-2s${NORMAL}%-14s${NORMAL}%-10s${NORMAL}%s${NORMAL}\n" "" "AMSS" "${AMSS_DB_PATCH_ID}" "${AMSS_REF_DMP}"
printf "%-2s${NORMAL}%-14s${NORMAL}%-10s${NORMAL}%s${NORMAL}\n" "" "OMS" "${OMS_DB_PATCH_ID}" "${OMS_REF_DMP}"
printf "%-2s${NORMAL}%-14s${NORMAL}%-10s${NORMAL}%s${NORMAL}\n" "" "SE" "${SE_DB_PATCH_ID}" "${SE_REF_DMP}"
printf "\n"

cleanTempFiles