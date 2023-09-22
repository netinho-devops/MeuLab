#!/bin/ksh




if [[ $# -ne 1 ]]
    then
     echo
     echo "USAGE : `basename $0` <Instance>"
     echo "     Example: `basename $0` NETCRM5"
     echo
     exit 1
fi

Date=`/bin/date '+%y%m%d_%H%M%S'`
inst=`echo $1 | tr '[a-z]' '[A-Z]'`
DirectoryPath=${HOME}/CRM/Backups/${inst}/${Date}

## ---  CreateDirectory  ------------------------- ##
#- Check if given directory exists and create it if
#  it doesn't.
## ----------------------------------------------- ##
CreateDirectory(){

if [ ! -d $DirectoryPath ]; then
   mkdir -p $DirectoryPath/Logs
   if [ $? -ne 0 ]; then
      echo "ERROR: could not create directory ${DirectoryPath}."
      exit
   else
      echo  "Directory $DirectoryPath created."
   fi
fi
}

BackupCrm(){

#export Date=`date '+%d/%m/%y'`

export Date=`/bin/date '+%y%m%d_%H%M%S'`


exp SA/SA@${inst} file=${DirectoryPath}/exp_SA_${inst}_${Date}.dmp log=${DirectoryPath}/Logs/exp_SA_${inst}_${Date}.log buffer=10000000 statistics=none

gzip ${DirectoryPath}/exp_SA_${inst}_${Date}.dmp

exp SAREF1/SAREF1@${inst} file=${DirectoryPath}/exp_SAREF1_${inst}_${Date}.dmp log=${DirectoryPath}/Logs/exp_SAREF1_${inst}_${Date}.log buffer=10000000 statistics=none

gzip ${DirectoryPath}/exp_SAREF1_${inst}_${Date}.dmp

exp SAREF2/SAREF2@${inst} file=${DirectoryPath}/exp_SAREF2_${inst}_${Date}.dmp log=${DirectoryPath}/Logs/exp_SAREF2_${inst}_${Date}.log buffer=10000000 statistics=none

gzip ${DirectoryPath}/exp_SAREF2_${inst}_${Date}.dmp

exp SACON/SACON@${inst} file=${DirectoryPath}/exp_SACON_${inst}_${Date}.dmp log=${DirectoryPath}/Logs/exp_SACON_${inst}_${Date}.log buffer=10000000 statistics=none

gzip ${DirectoryPath}/exp_SACON_${inst}_${Date}.dmp

}

CreateDirectory
BackupCrm

exit
