#!/usr/bin/ksh
errExit()
{
   echo "[ERROR] : " $1 >> $LOGFILE
   exit 1
}

getData()
{
if [[ "${1}" = "INS" ]] then 
   inProd="InSight";
else
   inProd="${1}";
fi

sqlplus -s $ensDetails<<EOF
set head off feedback off
set lines 100
set pages 0
spool ${logLocation}/${1}_envs.txt
select distinct signature from enspool where PRODUCT like '${inProd}' and (signature like 'bss%' OR upper(signature) like '${inProd}WRK1%');
spool off
EOF
}


getStorage()
{

     while read env
     do
        echo "------------ Checking env $env -------------" >> $LOGFILE
        envHost=`echo $env | cut -d"@" -f2`;
        envName=`echo $env | cut -d"@" -f1`;
        envProd=${1};
        if [[ "${1}" = "INS" ]] then
           envProd="INSIGHT1";
        fi
        ant -f ${scriptLocation}/getStorage.xml -DenvProd=${envProd} -DenvName=${envName} -DenvHost=${envHost} -DoutFile=${logLocation}/$$_list.txt > /dev/null
        #if [[ $? -ne 0 ]] then
        #    errExit "Failed to get storage for env : $env";
        #fi
     
     done<${logLocation}/${1}_envs.txt

}

getStgAge()
{
   stgCreDate=`head -n 1 ${storageHome}/${iVer}/${p}/${s}/.xpi/installations/.XPIStorageVersionInfo/xpiStorageInfo | sed 's/#//g'`;
   sMon=`echo ${stgCreDate} | cut -d" " -f2`;
   case ${sMon} in
        "Jan") sMon=1
        ;;
        "Feb") sMon=2
        ;;
        "Mar") sMon=3
        ;;
        "Apr") sMon=4
        ;;
        "May") sMon=5
        ;;
        "Jun") sMon=6
        ;;
        "Jul") sMon=7
        ;;
        "Aug") sMon=8
        ;;
        "Sep") sMon=9
        ;;
        "Oct") sMon=10
        ;;
        "Nov") sMon=11
        ;;
        "Dec") sMon=12
        ;;
   esac
   sDay=`echo ${stgCreDate} | cut -d" " -f3`;
   sYear=`echo ${stgCreDate} | cut -d" " -f6`;
   stgCreDate=`echo ${sDay}/${sMon}/${sYear}`;
   
   stgAge=`${scriptLocation}/date_diff.pl ${stgCreDate} ${tDate}`;  
}

purgeStg()
{
     sProd=`echo $1 | cut -d"_" -f2`;
     sVer=`echo $1 | cut -d"_" -f3 |sed 's/V//g'`;
     sBno=`echo $1 | cut -d"_" -f4 |sed 's/B//g'`;
     todayDate=`date +"%d_%m_%Y"`;
     #
     # Things to do:
     #   - remove stg directory
     #   - remove Build relese
     #   - remove entry from stg registeration table.
     #
     echo "Moving : mv ${storageHome}/${sVer}/${sProd}/${1} ${storageHome}/${sVer}/${sProd}/${1}_MARK_DEL_${todayDate}" >> $LOGFILE
     mv ${storageHome}/${sVer}/${sProd}/${1} ${storageHome}/${sVer}/${sProd}/${1}_MARK_DEL_${todayDate}
     #sqlplus -s ${ensDetails}<<EOF
     #set head off feedback off
     #set lines 100
     #set pages 0
     #     delete from GNS_STORAGE_REGISTRATION where STORAGE_NAME like '${1}';
     #     commit;
     #EOF
     if [[ "${p}" = "ABP" ]] then
                         variant="64";
                     else 
                         variant="64OG"
                     fi
     


}

#
# ----------- MAIN ------------------------
#


#
# Global Var
#
tDate=`date +"%d/%m/%Y"`;
#
# Getting input file and reading all vars
#

if [[  ! -f $1 ]] then 
    echo "[ERROR] :Input file $1 does not exist. Exiting ";
    exit 1;
fi
#
# Sourcing input file to get all vars
#
. $1
LOGFILE=${logLocation}/XPISTORAGE_CLEANUP_`date "+%Y_%m_%d_%H_%M_%S"`.log;

#
# Checking for all required support script
#

if [[ ! -f ${scriptLocation}/date_diff.pl || ! -f ${scriptLocation}/getStorage.xml ]] then
    errExit "Required support scripts date_diff.pl or getStorage.xml are missing from ${scriptLocation}. Exiting.";
fi


reqVars="storageHome prodList mailList logLocation scriptLocation iVer iDays ensDetails DUMMY_DELETE";

#
# Checking if all required variables are present
#
if [[ "$storageHome" = "" ]] then
   errExit "Required Variable storageHome is missing from input file. Exiting ";
fi

if [[ "$prodList" = "" ]] then
   errExit "Required Variable prodList is missing from input file. Exiting ";
fi
if [[ "$mailList" = "" ]] then
   errExit "Required Variable mailList is missing from input file. Exiting ";
fi
if [[ ! -d $logLocation ]] then
   errExit "Log File location $logLocation does not exist. Exiting";
fi
if [[ ! -d $scriptLocation ]] then
   errExit "Script location $scriptLocation does not exist. Exiting";
fi
if [[ "`echo $iVer | tr -d [:digit:]`" != "" ]] then
   errExit "Only Numbers are allowed in version parameter.";
fi
if [[ "`echo $iDays | tr -d [:digit:]`" != "" ]] then
   errExit "Only Numbers are allowed in Number of Days parameter.";
fi
if [[ "$ensDetails" = "" ]] then
   errExit "Required Variable ensDetails is missing from input file. Exiting ";
fi

#
# test if DB details are good and spool file can be created
#

echo "select count(*) from enspool;" | sqlplus $ensDetails > /tmp/$$_test.txt 2>&1

if [[ `grep ORA- /tmp/$$_test.txt | wc -l` -gt 0 ]] then
   errExit "Problems with Login to Ensight Database, error is : `grep ORA- /tmp/$$_test.txt`";
fi

rm -f /tmp/$$_test.txt;


#
# Create account list for all products
#
rm -f ${logLocation}/stg_env_list_${iVer}.csv;
touch ${logLocation}/stg_env_list_${iVer}.csv;
for p in $prodList  # LOOP 1.0 - For each product
do
   # Get list of all Envs in your product
   getData $p
   if [[ $? -ne 0 ]] then
       errExit "Failed at getData function for input : Product=${p} Version=${iVer}";
   fi
   # Get names of storages to which above envs look at
   getStorage $p
   #if [[ $? -ne 0 ]] then
   #    errExit "Failed at getStorage function for input : Product=${p} Version=${iVer}";
   #fi
   #
   # If for a given product, env list is less than 2 envs or SPOOL file has less than 2 envs dont delete storages
   #
   if [[ `grep "@" ${logLocation}/${p}_envs.txt | wc -l` -gt 2  ]] then
       #
       # For every existing storage, check number of envs pointing to it,
       # if referring envs > 0, add to CSV file else add to deletion list
       #
       
       cd ${storageHome}/${iVer}/${p}/;
       for s in `ls | grep ST_${p}_V${iVer}_B[0-9]*$ | grep -v MARK_DEL` # LOOP1.1 - For each storage of given Product, Version
       do
            #-------------------- For each storage in Product/Version,
            #-------------------- check which accounts refer to this storage
            if [[ "${DEV_STG}" != "TRUE" ]] then 
            refAcct=`grep -w ${s} ${logLocation}/$$_list.txt | cut -d"@" -f1-2`;
            else 
            refAcct=0;
		echo "Setting refAcct as 0 for $s";
            fi
            #  If no accounts refer to storage, add it to list for removal
            #  else, put it in report file.
            if [[ `echo ${refAcct} | wc -c ` -gt 2 ]] then
                 repList="";
                 for e in `echo $refAcct`
                 do
                    repList=`echo ${repList}:${e}`;
                 done
                 echo "${s} , ${repList}" >> ${logLocation}/stg_env_list_${iVer}.csv;
                 
            else 
                 #
                 #  Determine age of storage
                 getStgAge;
                 if [[ $? -ne 0 ]] then
                      errExit "Failed at getStgAge function for input : Storage=${s}";
                 fi
                 echo "HARSHAL : Found non-referred storage ${s} , age is $stgAge ";
                 #echo " Press any Key";
                 #read DKBOSE; 
                 if [[ $stgAge -gt $iDays ]] then
                     delStg=`echo ${delStg} ${s}`;
                 fi
            fi
       done #Loop1.1
       for stg in `echo $delStg`  #LOOP1.2 - For each storage which should be MARK_DEL
       do
          #if [[ "${DUMMY_DELETE}" = "N" ]] then
             purgeStg $stg;
          #fi
          echo "Will clean storage $stg" ;
       done #LOOP1.2
       #read DKBOSE;
       #
       # In DEV Mode, checking if all storages are moved,
       # If all storages are moved, recovering the latest storage
       #
       stgRemain=`ls | grep ST_${p}_V${iVer}_B[0-9]*$ | grep -v MARK_DEL`;
       if [[ ${DEV_STG} = "TRUE" ]] 
       then
          if [[ ${stgRemain} = "" ]]
          then
          #
          # Loop over all MARK_DEL storages and then recover the highest number
          #
          recoNum=0;
          for s in `ls | grep ST_${p} | grep MARK_DEL` 
          do
             n1=`echo $s | cut -d"_" -f4 | sed 's/B//g'`;
             if [[ $n1 -gt $recoNum ]] then 
                 recoNum=$n1;
             fi
          done
          #
          # Now recoNum has the highest number, use it to recover the newest storage
          #
          fi
          mv ST_${p}_V${iVer}_B${recoNum}_MARK_DEL* ST_${p}_V${iVer}_B${recoNum};
       fi
       
       
       #
       # Take action on all marked storages
       #
       for s in `ls | grep ST_${p} | grep MARK_DEL` #LOOP1.3
       do
           markDate=`echo $s | cut -d"_" -f7- | sed 's/_/\//g'`
           if [[ `${scriptLocation}/date_diff.pl ${markDate} ${tDate}` -gt $iDays ]] then
               
               echo "DELETING FOLDER : $s " >> $LOGFILE
                  if [[ "${DUMMY_DELETE}" = "N" ]] then
                     echo "DUMMY DELETE is set to N";
                     rm -rf $s;
                     s1=`echo $s | cut -d"_" -f1-4`;
                     n1=`echo $s1 | cut -d"_" -f4 | sed 's/B//g'`;
                     sqlplus  ${ensDetails}<<EOF
                     set head off feedback off
                     set lines 100
                     set pages 0
                          delete from GNS_STORAGE_REGISTRATION where STORAGE_NAME like '${s1}';
                          commit;
EOF
                     # Also removing BN folder 
                     if [[ "${p}" = "ABP" ]] then
                         variant="64";
                     else 
                         variant="64OG"
                     fi
                     echo "Deleting BN folder : ${storageHome}/BUILD_RELEASE/${p}/v${iVer}/${variant}/BN_${n1}";
##                     rm -rf ${storageHome}/BUILD_RELEASE/${p}/v${iVer}/${variant}/BN_${n1};
                     
                  fi
           fi
       
       done #LOOP1.3
       
   fi
   
done #LOOP1.0

echo "+++++++++ Sending Mail +++++++++++" >> $LOGFILE
echo "Attached mail contains list of active storages and envs pointing to them." | mailx -a ${logLocation}/stg_env_list_${iVer}.csv -s "Storage Env List for version ${iVer}" BSSPackInfraInt@int.amdocs.com;

echo "=============== Script has finished execution THE END ================" >> $LOGFILE

