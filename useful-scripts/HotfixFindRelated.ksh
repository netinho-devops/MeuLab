#!/bin/ksh

################################################################################
#                                                                              #
# Name: Find_HF.sh                                                             #
#                                                                              #
# Author: Camila Bellentani and Lucas Silva                                    #
#                                                                              #
# Date: May 2014                                                               #
#                                                                              #
# Description: The script searches for the files present in a hotfix in        #
#              others hotfixes                                                 #
#                                                                              #
################################################################################


HOTFIX_TOOL_PROFILE=/tifuser1/tif/aimsys/intamc/hotfix/hotfix_init_profile.ksh

#############
#USAGE
############

Usage () 
{
        cat <<END
SYNOPSIS
        Find_HF.sh <HOTFIX_ID>

DESCRIPTION
        Find the HFs which change the same files whose are on the HF that you looking for.

END

        exit $1
}


#############
#MAIN
############

if [ $# -ne 1 ]; then
    Usage 1
fi

HOTFIX_ID=${1}

. $HOTFIX_TOOL_PROFILE

cd $HOTFIX_HOME/HOTFIX
HOTFIX_PATH=$(find . -type d -name "*$HOTFIX_ID*")
if [[ -z $HOTFIX_PATH ]]; then
  echo -e "\nHotfix does not exist\n"
  exit
fi

echo -e "\033[35m\nHotfix Path: ${HOTFIX_HOME}/HOTFIX${HOTFIX_PATH#.}\033[0m\n"

for file in $(ls -1 ${HOTFIX_PATH} | egrep -v '(*.txt|temp)'); do
  OCCURRENCE=$(find . -type f -name "$file" | grep -v $HOTFIX_ID)
  if [[ -n $OCCURRENCE ]]; then
    echo -e "\033[32m$file is present in\033[0m"
    find . -type f -name "$file" | xargs md5sum | grep -v $HOTFIX_ID
    echo
  fi
done

