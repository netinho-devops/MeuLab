#!/usr/bin/ksh 

#
# Script to trigger squish on UNIX
# Parameters expected: CRM HOST and CRM USER
#
CrmHost=$1;
CrmUser=$2;
set -A TEAM
#
# Error Handler function
#
errExit()
{
   echo "[ERROR] : " $1 
   exit 1;
}

#
# Step 1 : Get CRM URL using available parameters
#
if [[ "${CrmHost}" = "" || "${CrmUser}" = "" ]] then
    errExit "One of the following required parameters [CrmUser CrmHost] is not supplied ";
fi
CrmPort=`ssh ${CrmUser}@${CrmHost} -n 'grep listen-port ${HOME}/JEE/CRMProduct/WLS/SmartClientDomain/config/config.xml | cut -d">" -f2 | cut -d"<" -f1'`

if [[ "${CrmPort}" = "" ]] then
    errExit "Crm UIF Port could not be evaluated from the CRM env $CrmUser."
fi 

CrmURL="http://${CrmHost}:${CrmPort}/Crm/CRM/Crm.jnlp";

#echo "Value of CRM URL is $CrmURL";

#
# Step 2 : Get timestamp and replace tokens of CRM URL and Last Name in tokenized test.js
#
TimeStamp=`date +"%d%m%Y%H%M%S"`;

#
# Check for config file and get all config params
#

if [[ -a SquishConfig.cfg ]] then
   . SquishConfig.cfg
else
    errExit "Squish Config file SquishConfig.cfg is missing at `pwd`";
fi

if [[ "${SquishHome}" = "" || "${SquishTestSuite}" = "" || "${SquishServerPort}" = "" || "${VPC_IP}" = "" ]] then
    errExit "One of the following required parameters [SquishHome SquishTestSuite SquishServerPort VPC_IP ] is not supplied in file SquishConfig.cfg";
fi

#
# getting Test Suite and Test Case
#
SqTestCase=`grep ^TEST_CASES ${SquishHome}/${SquishTestSuite}/suite.conf | cut -d"=" -f2`;

if [[ "$SqTestCase" = "" ]] then
    errExit "Squish Test Case not found in Squish installation";
fi

if [[ ! -a ${SquishHome}/${SquishTestSuite}/${SqTestCase}/test.js_TOKEN ]] then
    errExit "Tokenized test.js is missing from  ${SquishHome}/${SquishTestSuite}/${SqTestCase} ";
fi

sed "s|%CrmURL%|${CrmURL}|g" ${SquishHome}/${SquishTestSuite}/${SqTestCase}/test.js_TOKEN > ${HOME}/temp/TOKEN_test.js_$$
sed "s|%TimeStamp%|${TimeStamp}|g" ${HOME}/temp/TOKEN_test.js_$$ > ${SquishHome}/${SquishTestSuite}/${SqTestCase}/${CrmUser}_test.js

mv ${SquishHome}/${SquishTestSuite}/${SqTestCase}/${CrmUser}_test.js ${SquishHome}/${SquishTestSuite}/${SqTestCase}/test.js
#
# Step 3 : Form command and trigger it 
# 
echo "RUNNING : ${SquishHome}/bin/squishrunner --host ${VPC_IP} --port ${SquishServerPort} --testsuite ${SquishHome}/${SquishTestSuite}"
retVal=`${SquishHome}/bin/squishrunner --host ${VPC_IP} --port ${SquishServerPort} --testsuite ${SquishHome}/${SquishTestSuite} | tee  ${SquishHome}/Logs/${CrmUser}.log | grep "Number of Errors:" | cut -d":" -f2`
if [[ ${retVal} -ne 0 ]] then 
    cat ${SquishHome}/Logs/${CrmUser}.log
    errExit " Squish Runner failed with Errors";
else 
    cat ${SquishHome}/Logs/${CrmUser}.log
    echo "Squish Runner Finished Successfully. Customer created with First Name = Noam and Last Name = $TimeStamp";
fi
rm -rf ${HOME}/temp/TOKEN_test.js_$$ 

