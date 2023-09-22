#!/bin/ksh -xv


#######################INIT SECTION########################
#   
#   Supervisor:   Slavik Leibovich
#
#   NAME :        MAT from jenkins 
#
#   USAGE       : Mat_From_Jenkins.ksh  <ENV_ID> <Job_Name> 
#
#   DATE        : 31-03-2015
#
############################################################


####################### variable ###########################

if [ $# -ne 3 ]
then
     print "\n\tUSAGE : `basename $0` <ENV_ID> <Job_Name> <JOB_URL>"
     exit 1
fi

#############################################################

###################### Initialization Area - Start #########

ENV_ID=$1
Job_Name=$2
JOB_URL=$3
IS_RUNNING=false

############################################################


curl -X POST $JOB_URL/view/All/job/$Job_Name/buildWithParameters --user mb_ccmps:ktv22! -d ENV_ID=$ENV_ID
sleep 360;

IS_RUNNING=`curl -sf "$JOB_URL/view/All/job/$Job_Name/lastBuild/api/xml?xpath=/*/building" | sed -e 's/<building>//' -e 's|</building>||'`



while [ $IS_RUNNING = "true" ]
do
    IS_RUNNING=`curl -sf "${JOB_URL}/view/All/job/$Job_Name/lastBuild/api/xml?xpath=/*/building" | sed -e 's/<building>//' -e 's|</building>||'`
    echo "RUNNING"
done 

STATUS=`curl -sf "$JOB_URL/view/All/job/$Job_Name/lastBuild/api/xml?xpath=/*/result" | sed -e 's/<result>//' -e 's|</result>||'`


if [[ ${STATUS} = "SUCCESS" ]] then
  exit 0;
else
  exit 1;
fi




    
 


   
