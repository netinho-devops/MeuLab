#!/bin/ksh -a

####################    DESCRIPTION SECTION   ##########################
#
#   NAME        : SetCredentialVIVO.ksh
#
#   PURPOSE     : Envelope script for SetCredentialVIVO.py
#                 Used to enabled global trust between domains
#
#   AUTHOR      : Noam Brodie
#   DATE        : 30/05/2013
#
#	REVIEW		: Antonio Ideguchi
#	DATE		: 03/05/2016
########################################################################

#-------------------------------------------------------+
#   P R I N T   U S G E
#-------------------------------------------------------+
print_usage()
{

    cat << END

USAGE
    SetCredentialVIVO.ksh <Product> <Domain Dir Path> <Credential>

DESCRIPTION
    Envelope script for SetCredential.py
    Used to enabled global trust between domains

EXAMPLE
    SetCredentialVIVO.ksh ABP /amxusers5/aimsys/abp/petabp3/J2EEServer/config/ABP-FULL8 weblogic

END

    exit 1
}


############################################################################
#######################
#####   MAIN     ######
#######################

if [[ $# -ne 3 ]]
then
    print "ERROR: missing input arguments!\n"
    print_usage
fi

PRODUCT=$1
DOMAIN_HOME=$2
CREDENTIAL=$3

. ${HOME}/.profile > /dev/null 2>&1

#export BASE_DIR=$( echo $( dirname $(whence $0) ) |sed 's/\(.*\)\/\./\1/' )
#export BASE_DIR=$( dirname $0 )
#export BASE_DIR="~/genesisTmpDir"

##########################

if [[ -f "${BEA_HOME}/common/bin/wlst.sh" ]]
then
    WLST_SH=${BEA_HOME}/common/bin/wlst.sh

elif [[ -f "${WL_HOME}/common/bin/wlst.sh" ]]
then
    WLST_SH=${WL_HOME}/common/bin/wlst.sh

elif [[ -f "${APP_VENDOR_HOME}/common/bin/wlst.sh" ]]
then
    WLST_SH=${APP_VENDOR_HOME}/common/bin/wlst.sh

elif [[ -f "${WL_HOME}/installation/wlserver/common/bin/wlst.sh" ]]
then
    WLST_SH=${WL_HOME}/installation/wlserver/common/bin/wlst.sh

elif [[ -f "${WL_HOME}/installation/oracle_common/common/bin/wlst.sh" ]]
then
    WLST_SH=${WL_HOME}/installation/oracle_common/common/bin/wlst.sh
else
    print "ERROR: Didn't found ${BEA_HOME}/common/bin/wlst.sh \n"
    exit 1
fi


if [[ ! -d "${DOMAIN_HOME}" ]]
then
    print "ERROR: ${DOMAIN_HOME} not exists\n"
    exit 1
fi


case $PRODUCT in
	"ABP") 
		print "\n\n Starting Global Trust Configuration (OFFLINE) \n\n"
		${WLST_SH} SetCredentialVIVO.py -m offline -d ${DOMAIN_HOME} -c ${CREDENTIAL}
		print "\n\n Starting Weblogic for ONLINE XA Transaction configuration \n\n"
		ksh StartABPWL.sh
		print "\n\n Starting XA Transaction Configuration (ONLINE) \n\n"
		${WLST_SH} SetXAABP.py -m online -d ${DOMAIN_HOME} -c ${CREDENTIAL} -u jeeadmin -t Jeeadmin1 -h ${WEBLOGIC_HOST} -p ${WEBLOGIC_PORT}
		;;
	*)
		${WLST_SH} SetCredentialVIVO.py -m offline -d ${DOMAIN_HOME} -c ${CREDENTIAL}
		;;
esac

if [[ $? -ne 0 ]]
then
    print "ERROR: SetCredential failed!\n"
    exit 1
fi

print "\nINFO: SetCredential.ksh finished successfuly."

exit 0

