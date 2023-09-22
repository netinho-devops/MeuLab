#!/usr/bin/ksh

#
# ========== MAIN ===========
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
LOGFILE=${logLocation}/BUILDREL_CLEANUP_`date "+%Y_%m_%d_%H_%M_%S"`.log;

#
# Checking for all required support script
#

if [[ ! -f ${scriptLocation}/date_diff.pl ]] then
    errExit "Required support script date_diff.pl is missing from ${scriptLocation}. Exiting.";
fi

reqVars="storageHome prodList mailList logLocation scriptLocation iVer iDays DUMMY_DELETE";

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


for p in $prodList
do
    if [[ "${p}" = "ABP" ]] then
       variant="64";
    else 
       variant="64OG";
    fi
    if [[ ! -d ${brHome}/${p}/v${iVer}/${variant} ]] then
       errExit "Folder ${brHome}/${p}/v${iVer}/${variant} not found. Exiting.";
    fi
    cd ${brHome}/${p}/v${iVer}/${variant};
    for bn in `ls | grep "BN_" | grep -v CURRENT`
    do
        #
        # Check if there exists a storage corresponding to this build number
        #
        bldNum=`echo $bn | cut -d"_" -f2`;
        if [[ ! -d ${storageHome}/${iVer}/${p}/ST_${p}_V${iVer}_B${bn} ]] then
             #
             # Since connected storage does not exist, get age of BN folder
             #
               
        fi
        
    done



done
