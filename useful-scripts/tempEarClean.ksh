#!/usr/bin/ksh

. ${HOME}/.profile;
targStg=$1;
stgVer=`echo $targStg | cut -d"_" -f3 | sed 's/V//g'`;
if [[ ! -d /XPISTORAGE/${stgVer}/AMSS/${targStg}/STORAGE/storage/AMSS/custom/tempEar ]] then
    echo " Directory  /XPISTORAGE/${stgVer}/AMSS/${targStg}/STORAGE/storage/AMSS/custom/tempEar does not exist ";
    echo " EXITING ";
    exit 1;
fi

cd /XPISTORAGE/${stgVer}/AMSS/${targStg}/STORAGE/storage/AMSS/custom/tempEar;
for e in `ls`
do
    ENVNUM=`echo $e | sed 's/bssams//g'`
    ENVDET=`amss $ENVNUM SHOW`
    echo " Cleaning from $ENVDET folder";
    ssh $ENVDET -n "rm -rf /XPISTORAGE/${stgVer}/AMSS/${targStg}/STORAGE/storage/AMSS/custom/tempEar/bssams${ENVNUM}"
done

