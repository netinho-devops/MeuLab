#!/bin/ksh
#MENU_DESCRIPTION=Generates Environment Release Mail - usage: utils_envRelease ENV_NUMBER PRODUCT VERSION PHASE
####################################
# Author: Rajkumar Nayeni, Eitan Corech, Lior Moldovan
# Edited: Pedro Pavan
# Purpose: To genrate Release mail
#
#
####################################


####################################################
#
#variableDefinition
#
##################################################
variableDefinition()
{

HOMEDIR="/vivnas/viv/vivtools"
SCRIPTHOMEDIR="`echo $HOMEDIR`/Scripts"
AMCDBString="tooladm/tooladm@$TOOLS_DB_INSTANCE"
PROJ_ABBR=viv

# Ping Script Locations
abpScriptPath="~/JEE/ABPProduct/scripts/ABP-FULL"
abpPingScript="pingABPServer.sh"
omsScriptPath="~/JEE/OMS/scripts/OmsDomain/OmsServer"
omsPingScript="pingOmsServer.sh"
crmScriptPath="~/JEE/CRMProduct/scripts/CRMDomain/CRMServer"
crmPingScript="pingCRMServer.sh"
uifScriptPath="~/JEE/CRMProduct/scripts/UIFDomain/UIFServer"
uifPingScript="pingUIFWebLogic.sh"
slrScriptPath="~/JEE/SolrProduct/scripts/SolrDomain_SolrServer/SolrServer"
slrPingScript="pingSolrServer.sh"
amssScriptPath="~/JEE/AMSSProduct/scripts/AMSSFullDomain/AMSSFullServer"
amssPingScript="pingAMSSFullServer.sh"
uxfScriptPath="~/JEE/LightSaber/scripts/LightSaberDomain"
uxfPingScript="pingLightSaberServer.sh"
slraScriptPath="~/JEE/SolrProduct/scripts/SolrDomain_SolrServer/SolrServer"
slraPingScript="pingSolrServer.sh"
omniScriptPath="~/JEE/LightSaberDomain/scripts/LightSaberDomain/omni_LSJEE"
omniPingScript="pingomni_LSJEE.sh"

TOOL_URL="http://${HOST}:5000"
CRM_STORAGE=""

EMAIL_TO=$([[ "${HOST}" = "indlin3662" ]] && echo "VIVODCCInfraMPSINT@int.amdocs.com;VivoSTLead@int.amdocs.com;VIVODCCStabilizationLead@int.amdocs.com;vivost@int.amdocs.com;VIVOUpgradeSupport@int.amdocs.com;VIVOMCSSCloneEnvsTeam@int.amdocs.com" || echo "VIVODCCInfraMPSINT@int.amdocs.com")
#EMAIL_TO="pedroa@amdocs.com"
#EMAIL_TO="hantonio@amdocs.com"
#EMAIL_TO="jyoti.wabale@amdocs.com"
#EMAIL_TO="rnayeni@amdocs.com"
#EMAIL_TO="vinayp@amdocs.com"
EMAIL_FROM="VIVODCCInfraMPSINT@int.amdocs.com"
#EMAIL_TO="darpank@amdocs.com"
#EMAIL_SUBJECT="${PROJECT} V${VERSION} - SWP #${SWP} - Env ${PHASE} #${ENV_NUMBER} - BSS Release Environment Report"
if [[ "${IS_GOLDEN}" = "N" ]]
then
	EMAIL_SUBJECT="VIVO V${VERSION} SWP#${SWP} ICM Build#${ICM_BUILD} Env #${ENV_NUMBER} - Release Environment Report"
else
	EMAIL_SUBJECT="VIVO V${VERSION} SWP#${SWP} ICM Build#${ICM_BUILD} Env #${ENV_NUMBER} - IaaS Golden Release Environment Report"
fi
TEAM="VIVO Infra Integration"

ABP_TIGER_CONNECT=$([[ "${HOST}" = "indlin3662" ]] && echo "TIGER_REP_ABP/TIGER_REP_ABP@VV9TOOLS" || echo "TIGER_REP_ABP/TIGER_REP_ABP@VVTOOLS")
OMS_TIGER_CONNECT=$([[ "${HOST}" = "indlin3662" ]] && echo "TIGER_REP_OMS/TIGER_REP_OMS@VV9TOOLS" || echo "TIGER_REP_OMS/TIGER_REP_OMS@VVTOOLS")
SE_TIGER_CONNECT=$([[ "${HOST}" = "indlin3662" ]] && echo "TIGER_REP_SE/TIGER_REP_SE@VV9TOOLS" || echo "TIGER_REP_SE/TIGER_REP_SE@VVTOOLS")
AMSS_TIGER_CONNECT=$([[ "${HOST}" = "indlin3662" ]] && echo "TIGER_REP_ECR/TIGER_REP_ECR@VV9TOOLS" || echo "TIGER_REP_MCSS/TIGER_REP_MCSS@VVTOOLS")

. ${HOMEDIR}/.profile >/dev/null 2>&1 </dev/null

}

####################################################
#
#FindUnixBox
#
##################################################

FindUnixBox()
{
ENV_NUMBER=$1
PRODUCT=$2
VERSION=$3
PHASE=$4

UNIXBOX=`sqlplus -s ${AMCDBString} << EOF 
set hea off feed off pagesize 0
select PROPERTY_VALUE 
from   GNS_ENV_PROPERTIES 
where  PROPERTY_VALUE like  '%${ENV_NUMBER}'
and    PRODUCT_ENV_ID = (select PRODUCT_ENV_ID 
                         from   GNS_PRODUCT_ENV_MODEL 
                         where PRODUCT_ID = (select PRODUCT_ID 
                                             from   GNS_PRODUCT 
                                             where  PRODUCT_NAME = '${PRODUCT}' )  
                        and  VERSION_ID  =  (select VERSION_ID
                                             from   GNS_VERSION 
                                             where  VERSION_NUMBER = ${VERSION} )  
                        and  PHASE_ID    =  (select PHASE_ID 
                                             from   GNS_ENV_PHASE 
                                             where  ENV_PHASE = '${PHASE}')) 
                       and PROPERTY_NAME =  'host' ;
exit;
EOF`

}

####################################################
#
#FindUnixBoxOther
#
##################################################

FindUnixBoxOther()
{
ENV_NUMBER=$1
PRODUCT=$2
VERSION=$3
PHASE=$4

UNIXBOX=`sqlplus -s ${AMCDBString} << EOF
set hea off feed off pagesize 0
select PROPERTY_VALUE
from   GNS_ENV_PROPERTIES
where  ENV_ID = ${ENV_NUMBER}
and    PRODUCT_ENV_ID = (select PRODUCT_ENV_ID
                         from   GNS_PRODUCT_ENV_MODEL
                         where PRODUCT_ID = (select PRODUCT_ID
                                             from   GNS_PRODUCT
                                             where  PRODUCT_NAME = '${PRODUCT}' )
                        and  VERSION_ID  =  (select VERSION_ID
                                             from   GNS_VERSION
                                             where  VERSION_NUMBER = ${VERSION} )
                        and  PHASE_ID    =  (select PHASE_ID
                                             from   GNS_ENV_PHASE
                                             where  ENV_PHASE = '${PHASE}'))
                       and PROPERTY_NAME =  'host' ;
exit;
EOF`

}






####################################################
#
#showEnvironmentDetails
#
##################################################
showEnvironmentDetails()
{
PRODUCT=`echo ${1} | tr '[A-Z]' '[a-z]'`
UNIXUSER=""
UNIXBOX=""
STORAGE=""

case ${PRODUCT} in
	abp)
		UNIXUSER=${PROJ_ABBR}abp${ENV_NUMBER}
		PRODUCT='enb'
		;;
	amss)
		UNIXUSER=vivmcs${ENV_NUMBER}
		;;
	omni)
		UNIXUSER=vivomn${ENV_NUMBER}
		;;
	slroms)
		UNIXUSER=vivslo${ENV_NUMBER}
		;;
	slrams)
		UNIXUSER=vivsla${ENV_NUMBER}
		;;
	*)
		UNIXUSER=${PROJ_ABBR}${PRODUCT}${ENV_NUMBER}
		;;
esac

if [[ "${PHASE}" = "CST" ]]
then
        if [[ "${PRODUCT}" = "enb" ]]
        then
                UNIXUSER=abpwrk1
        elif [[ "${PRODUCT}" = "amss" ]]
        then
                UNIXUSER=amswrk1
        elif [[ "${PRODUCT}" = "slroms" ]]
        then
                UNIXUSER=slroms1
        elif [[ "${PRODUCT}" = "slrams" ]]
        then
                UNIXUSER=slrams1
        elif [[ "${PRODUCT}" = "omni" ]]
        then
                UNIXUSER=omnwrk1
        else
                UNIXUSER=${PRODUCT}wrk1
        fi
fi
if [[ "${PHASE}" = "TRN" ]]
then
case ${PRODUCT} in
        enb)
                UNIXUSER=trnabp${ENV_NUMBER}
                PRODUCT='enb'
                ;;
        amss)
                UNIXUSER=trnmcs${ENV_NUMBER}
                ;;
        slroms)
                UNIXUSER=trnslo${ENV_NUMBER}
                ;;
        slrams)
                UNIXUSER=trnsla${ENV_NUMBER}
                ;;
        omni)
                UNIXUSER=trnomn${ENV_NUMBER}
                ;;
        *)
                UNIXUSER=trn${PRODUCT}${ENV_NUMBER}
                ;;
esac
fi

if [[ "${PHASE}" = "CST" ]] 
then
	FindUnixBox ${ENV_NUMBER} ${PRODUCT} ${VERSION} ${PHASE}
else
	FindUnixBoxOther ${ENV_NUMBER} ${PRODUCT} ${VERSION} ${PHASE}
fi

case $1 in
        ABP)
               	if [[ "${PHASE}" = "CST" ]] 
				then
					export STORAGE=`ssh -q ${UNIXUSER}@${UNIXBOX} -n "ls -alrt ~/abp_home| cut -d"/" -f9"`
				else
					export STORAGE=`ssh -q ${UNIXUSER}@${UNIXBOX} -n "ls -alrt ~/abp_home| cut -d"/" -f10"`
				fi
                ;;
        CRM)
	        #V#export version=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd .xpi/repository/topologies; grep ST_CRM * 2>/dev/null |cut -d"/" -f5 | cut -d "_" -f4 | sed "s/B//" | uniq "`
	        export version=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd .xpi/repository/topologies; grep ST_CRM * 2>/dev/null |cut -d"/" -f3 | uniq "`
		export build_number=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd .xpi/repository/topologies; grep ST_CRM * 2>/dev/null | cut -d"/" -f5 | cut -d "_" -f4 | sed "s/B//" | uniq"`
                export STORAGE=ST_CRM_V${version}_B${build_number}
		CRM_STORAGE=ST_CRM_V${version}_B${build_number}
                ;;
        OMS)
                export version=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd .xpi/repository/topologies; grep ST_O * 2>/dev/null | cut -d"/" -f5 | cut -d "_" -f3 | sed "s/V//" | uniq"`
		export build_number=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd .xpi/repository/topologies; grep ST_O * 2>/dev/null | cut -d"/" -f5 | cut -d "_" -f4 | sed "s/B//" | uniq"`
                export STORAGE=ST_OMS_V${version}_B${build_number}
                ;;
	SLROMS)
                export version=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cat ~/storage_root/packages/slroms_build.number | grep 'build.version' | cut -d '=' -f2 | cut -d "v" -f2"`
                export build_number=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cat ~/storage_root/packages/slroms_build.number | grep 'build.number' | cut -d '=' -f2 | head -1"`
                export STORAGE=ST_SLROMS_${version}_B${build_number}
                ;;
	SLRAMS)
                export version=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cat ~/storage_root/packages/slrams_build.number | grep 'build.version' | cut -d '=' -f2 | cut -d "v" -f2"`
                export build_number=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cat ~/storage_root/packages/slrams_build.number | grep 'build.number' | cut -d '=' -f2 | head -1"`
                export STORAGE=ST_SLRAMS_${version}_B${build_number}
                ;;
    AMSS)
				export version=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd .xpi/repository/topologies; grep ST_AM * 2>/dev/null | cut -d"/" -f5 | cut -d "_" -f3 | sed "s/V//" | uniq"`
				export build_number=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd .xpi/repository/topologies; grep ST_AM * 2>/dev/null | cut -d"/" -f5 | cut -d "_" -f4 | sed "s/B//" | uniq"`
				export STORAGE=ST_AMSS_${version}_B${build_number}
				;;
	 OMNI)
				export version=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd ~/storage_root; pwd -P 2>/dev/null | cut -d"/" -f3 | cut -d "_" -f3 | sed "s/B//" | uniq"`
				export build_number=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cat ~/storage_root/packages/omni_build.number | grep 'build.number' | cut -d '=' -f2 | head -1"`
				export STORAGE=ST_OMNI_${version}_B${build_number}
				;;
	 WSF)
				export version=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd ~/storage_root; pwd -P 2>/dev/null | cut -d"/" -f3 | cut -d "_" -f3 | sed "s/B//" | uniq"`
				export build_number=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cat ~/storage_root/packages/wsf_build.number | grep 'build.number' | cut -d '=' -f2 | head -1"`
				export STORAGE=ST_WSF_${version}_B${build_number}
				;; 
	*)
                echo "please give product Name $1"
                exit 1
                ;;
esac

if [ "`expr ${ROWNUMBER} % 2 `" == "0" ]
then
        echo "<tr bgcolor='A5D5E2'>"
else
        echo "<tr bgcolor='D2EAF1'>"
fi

echo "<td bgcolor='4BACC6'> <b> `echo ${PRODUCT} | tr '[a-z]' '[A-Z]'` </b> </td>"
echo "<td> ${UNIXUSER}/Unix11! </td>"
echo "<td> ${UNIXBOX} </td>"
echo "<td> ${STORAGE} </td>"
echo "</tr> "

ROWNUMBER=`expr ${ROWNUMBER} + 1`
}

#########################################################################
#
# showEnvironmentDumps
#
#########################################################################
showEnvironmentDumps()
{

ABP_BUILD_NUMBER_S=`sqlplus -s $ABP_TIGER_CONNECT <<!       
        set pages 0;
        set heading off;
        set feedback off;
        select max(BUILD_ID) 
        from ccbuilds_dbpatches
        where CC_VERSION='${VERSION}' ;
      !`
typeset -i ABP_BUILD_NUMBER=${ABP_BUILD_NUMBER_S}

ABP_REF_DMP=`sqlplus -s $ABP_TIGER_CONNECT <<!       
        set pages 0;
        set heading off;
        set feedback off;
        select OPT1 
        from ccbuilds_dbpatches
        where  BUILD_ID='${ABP_BUILD_NUMBER}' and CC_VERSION='${VERSION}' ;
      !`

ABP_DB_PATCH_S=`sqlplus -s $ABP_TIGER_CONNECT <<!  
        set pages 0;
        set heading off;
        set feedback off;
        select PATCH_ID 
        from ccbuilds_dbpatches
        where  BUILD_ID='${ABP_BUILD_NUMBER}' and CC_VERSION='${VERSION}' ;
      ! `

#typeset -i ABP_DB_PATCH=${ABP_DB_PATCH_S}
ABP_DB_PATCH=`echo ${ABP_DB_PATCH_S}`

#OMS INFO

OMS_BUILD_NUMBER_S=`sqlplus -s $OMS_TIGER_CONNECT <<!       
        set pages 0;
        set heading off;
        set feedback off;
        select max(BUILD_ID) 
        from ccbuilds_dbpatches
        where CC_VERSION='${VERSION}' ;
      !`

typeset -i OMS_BUILD_NUMBER=${OMS_BUILD_NUMBER_S}

OMS_PC_DMP=`sqlplus -s $OMS_TIGER_CONNECT <<!       
        set pages 0;
        set heading off;
        set feedback off;
        select OPT1 
        from ccbuilds_dbpatches
        where  BUILD_ID='${OMS_BUILD_NUMBER}' and CC_VERSION='${VERSION}' ;
      !`

OMS_AIF_DMP=`sqlplus -s $OMS_TIGER_CONNECT <<!       
        set pages 0;
        set heading off;
        set feedback off;
        select OPT2 
        from ccbuilds_dbpatches
        where  BUILD_ID='${OMS_BUILD_NUMBER}' and CC_VERSION='${VERSION}' ;
      !`

OMS_DB_PATCH_S=`sqlplus -s $OMS_TIGER_CONNECT <<!       
        set pages 0;
        set heading off;
        set feedback off;
        select PATCH_ID 
        from ccbuilds_dbpatches
        where  BUILD_ID='${OMS_BUILD_NUMBER}' and CC_VERSION='${VERSION}' ;
      !`

#typeset -i OMS_DB_PATCH=${OMS_DB_PATCH_S}
OMS_DB_PATCH=`echo ${OMS_DB_PATCH_S}`

#OPX INFO
OPX_BUILD_NUMBER_S=`sqlplus -s $SE_TIGER_CONNECT <<!       
        set pages 0;
        set heading off;
        set feedback off;
        select max(BUILD_ID) 
        from ccbuilds_dbpatches
        where CC_VERSION='${VERSION}' ;
      !`

typeset -i OPX_BUILD_NUMBER=${OPX_BUILD_NUMBER_S}

SLR_DMP=`sqlplus -s $SE_TIGER_CONNECT <<!       
        set pages 0;
        set heading off;
        set feedback off;
        select OPT1 
        from ccbuilds_dbpatches
        where  BUILD_ID='${OPX_BUILD_NUMBER}' and CC_VERSION='${VERSION}' ;
      !`

OPX_DB_PATCH_S=`sqlplus -s $SE_TIGER_CONNECT <<!       
        set pages 0;
        set heading off;
        set feedback off;
        select PATCH_ID 
        from ccbuilds_dbpatches
        where  BUILD_ID='${OPX_BUILD_NUMBER}' and CC_VERSION='${VERSION}' ;
      !`
#typeset -i OPX_DB_PATCH=${OPX_DB_PATCH_S}
OPX_DB_PATCH=`echo ${OPX_DB_PATCH_S}`


#AMSS
AMSS_BUILD_NUMBER_S=`sqlplus -s $AMSS_TIGER_CONNECT <<!
        set pages 0;
        set heading off;
        set feedback off;
        select max(BUILD_ID)
        from ccbuilds_dbpatches
        where CC_VERSION='${VERSION}' ;
      !`

typeset -i AMSS_BUILD_NUMBER=${AMSS_BUILD_NUMBER_S}

AMSS_SEC_DMP=`sqlplus -s $AMSS_TIGER_CONNECT <<!
        set pages 0;
        set heading off;
        set feedback off;
        select OPT1
        from ccbuilds_dbpatches
        where  BUILD_ID='${AMSS_BUILD_NUMBER}' and CC_VERSION='${VERSION}' ;
      !`

AMSS_DB_PATCH_S=`sqlplus -s $AMSS_TIGER_CONNECT <<!
        set pages 0;
        set heading off;
        set feedback off;
        select PATCH_ID
        from ccbuilds_dbpatches
        where  BUILD_ID='${AMSS_BUILD_NUMBER}' and CC_VERSION='${VERSION}' ;
      !`
#typeset -i AMSS_DB_PATCH=${AMSS_DB_PATCH_S}
AMSS_DB_PATCH=`echo ${AMSS_DB_PATCH_S}`

APX_SE_DMP=`sqlplus -s $AMSS_TIGER_CONNECT <<!
        set pages 0;
        set heading off;
        set feedback off;
        select OPT2
        from ccbuilds_dbpatches
        where  BUILD_ID='${AMSS_BUILD_NUMBER}' and CC_VERSION='${VERSION}' ;
      !`


#V#CRM_STORAGE_ICM_BNUM=`grep ICM.build.number=${i_ICM} /XPISTORAGE/${VERSION}/CRM/$CRM_STORAGE/packages/crm_build.number | tail -1 | awk -F'/' '{print $5}'`
#CRM_DMP_LOCATION="/XPISTORAGE/${VERSION}/CRM/${CRM_STORAGE}/crm.dmp.gz"
#CRM_DMP=`ls -l ${CRM_DMP_LOCATION} | awk -F'>' '{print $NF}'`

#kovas i_ICM

echo "<tr bgcolor='A5D5E2'>"
echo "<td> <b> ABP </b> </td>"
echo "<td> ${ABP_DB_PATCH} </td>"
echo "<td> REFERENCE </td>"
echo "<td> ${ABP_REF_DMP} </td>"
echo "</tr> "

echo "<tr bgcolor='D2EAF1'>"
echo "<td rowspan="3"> <b> OMS </b> </td>"
echo "<td rowspan="3"> ${OMS_DB_PATCH} </td>"
echo "</tr> "
echo "<tr bgcolor='D2EAF1'>"
echo "<td> PC </td>"
echo "<td> ${OMS_PC_DMP} </td>"
echo "</tr> "
echo "<tr bgcolor='D2EAF1'>"
echo "<td> AIF </td>"
echo "<td> ${OMS_AIF_DMP} </td>"
echo "</tr> "

echo "<tr bgcolor='A5D5E2'>"
echo "<td> <b> CRM </b> </td>"
echo "<td> NA </td>"
echo "<td> REFERENCE </td>"
echo "<td>/XPISTORAGE/${VERSION}/CRM/${CRM_STORAGE}/STORAGE/CRM/custom9/dbadmin/dump/crm.dmp.gz </td>"
echo "</tr> "

echo "<tr bgcolor='D2EAF1'>"
echo "<td> <b> SLROMS </b> </td>"
echo "<td> ${OPX_DB_PATCH} </td>"
echo "<td> REFERENCE(SE) &nbsp;&nbsp;</td>"
echo "<td> ${SLR_DMP} </td>"
echo "</tr> "

echo "<tr bgcolor='A5D5E2'>"
echo "<td> <b> AMSS </b> </td>"
echo "<td> ${AMSS_DB_PATCH} </td>"
echo "<td> NA  </td>"
echo "<td> NA  </td>"
echo "</tr> "



}

#########################################################################
#
#showGeneralInformation
#
#########################################################################
showGeneralInformation()
{
if [ "`expr ${ROWNUMBER} % 2 `" = "0" ]
then
        echo "<tr bgcolor='A5D5E2'>"
else
        echo "<tr bgcolor='D2EAF1'>"
fi

echo "<td bgcolor='4BACC6'> <b> AMC Tools URL </b> </td>"
echo "<td> ${TOOL_URL} </td>"
echo "<td> NT Name/Pass </td>"

ROWNUMBER=`expr ${ROWNUMBER} + 1`
}

#########################################################################
#
#showProductsDetails
#
#########################################################################
showProductsDetails()
{
## kovas
UNIXUSER=""
UNIXBOX=""
STORAGE=""

if [[ "${PHASE}" = "CST" ]]
then
UNIXUSER=crmwrk1
elif [[ "${PHASE}" = "TRN" ]]
then
UNIXUSER=trncrm${ENV_NUMBER}
else
UNIXUSER=${PROJ_ABBR}crm${ENV_NUMBER}
fi

if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} crm ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} crm ${VERSION} ${PHASE}
fi


#FindUnixBox ${ENV_NUMBER} crm ${VERSION} ${PHASE}
export CRMSMARTCLIENTURL=`ssh -q ${UNIXUSER}@${UNIXBOX} -n " . ./.profile 2>/dev/null | grep 'SmartClient URL' | cut -d ':' -f2-"`

if [ "`expr ${ROWNUMBER} % 2 `" = "0" ]
then
        echo "<tr bgcolor='A5D5E2'>"
else
        echo "<tr bgcolor='D2EAF1'>"
fi

echo "<td bgcolor='4BACC6'> <b> SmartClient </b> </td>"
echo "<td> ${CRMSMARTCLIENTURL} </td>"
echo "<td> Asmsa1/Asmsa1 </td>"

ROWNUMBER=`expr ${ROWNUMBER} + 1`

if [[ "${PHASE}" = "CST" ]]
then
UNIXUSER=omswrk1
elif [[ "${PHASE}" = "TRN" ]]
then
UNIXUSER=trnoms${ENV_NUMBER}
else
UNIXUSER=${PROJ_ABBR}oms${ENV_NUMBER}
fi

if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} oms ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} oms ${VERSION} ${PHASE}
fi



#FindUnixBox ${ENV_NUMBER} oms ${VERSION} ${PHASE}
export OMSSMARTCLIENTURL=`ssh -q ${UNIXUSER}@${UNIXBOX} -n " . ./.profile 2>/dev/null | grep 'LAUNCH URL' | cut -d '=' -f2"`

if [ "`expr ${ROWNUMBER} % 2 `" = "0" ]
then 
        echo "<tr bgcolor='A5D5E2'>"
else 
        echo "<tr bgcolor='D2EAF1'>"
fi 

echo "<td bgcolor='4BACC6'> <b> OMS Launch URL </b> </td>"
echo "<td> ${OMSSMARTCLIENTURL} </td>"
echo "<td> Asmsa1/Asmsa1 </td>"

ROWNUMBER=`expr ${ROWNUMBER} + 1`

if [[ "${PHASE}" = "CST" ]]
then
	UNIXUSER=slroms1
elif [[ "${PHASE}" = "TRN" ]]
then
    UNIXUSER=trnslo${ENV_NUMBER}
else
	UNIXUSER=vivslo${ENV_NUMBER}
fi

#FindUnixBox ${ENV_NUMBER} slroms ${VERSION} ${PHASE}

if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} slroms ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} slroms ${VERSION} ${PHASE}
fi


export SLRURL=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ' . ./.profile 2>/dev/null ; alias | grep solrlink  | cut -d "\"" -f2'`

if [ "`expr ${ROWNUMBER} % 2 `" = "0" ]
then
        echo "<tr bgcolor='A5D5E2'>"
else
        echo "<tr bgcolor='D2EAF1'>"
fi

echo "<td bgcolor='4BACC6'> <b> SLR URL </b> </td>"
echo "<td> ${SLRURL} </td>"
echo "<td>  </td>"

ROWNUMBER=`expr ${ROWNUMBER} + 1`

if [[ "${PHASE}" = "CST" ]]
then
	UNIXUSER=wsfwrk1
elif [[ "${PHASE}" = "TRN" ]]
then
UNIXUSER=trnwsf${ENV_NUMBER}
else
	UNIXUSER=vivwsf${ENV_NUMBER}
fi
#FindUnixBox ${ENV_NUMBER} wsf ${VERSION} ${PHASE}
if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} wsf ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} wsf ${VERSION} ${PHASE}
fi
export WSF_SERVICES_URL=`ssh -q ${UNIXUSER}@${UNIXBOX} -n " . ./.profile 2>/dev/null | grep 'SERVICES URL' | cut -d '=' -f2"`
if [ "`expr ${ROWNUMBER} % 2 `" = "0" ]
then
        echo "<tr bgcolor='A5D5E2'>"
else
        echo "<tr bgcolor='D2EAF1'>"
fi
echo "<td bgcolor='4BACC6'> <b> WSF SERVICES URL </b> </td>"
echo "<td> ${WSF_SERVICES_URL} </td>"
echo "<td>  </td>"
ROWNUMBER=`expr ${ROWNUMBER} + 1`
}

#############################################################
#
#showServerStatus
#
#########################################################
showServerStatus() 
{
PRODUCT=`echo ${1} | tr '[A-Z]' '[a-z]'`
UNIXUSER=""
UNIXBOX=""
STORAGE=""

case ${PRODUCT} in
        abp)
                UNIXUSER=${PROJ_ABBR}abp${ENV_NUMBER}
                PRODUCT='enb'
                ;;
       amss)
                UNIXUSER=vivmcs${ENV_NUMBER}
                ;;
       slroms)
                UNIXUSER=vivslo${ENV_NUMBER}
                ;;
       slrams)
                UNIXUSER=vivsla${ENV_NUMBER}
                ;;
       omni)
                UNIXUSER=vivomn${ENV_NUMBER}
                ;;
       *)
                UNIXUSER=${PROJ_ABBR}${PRODUCT}${ENV_NUMBER}
                ;;
esac

if [[ "${PHASE}" = "CST" ]]
then
        if [[ "${PRODUCT}" = "enb" ]]
        then
                UNIXUSER=abpwrk1
       	elif [[ "${PRODUCT}" = "amss" ]] 
		then
				UNIXUSER=amswrk1
		elif [[ "${PRODUCT}" = "slroms" ]]
        then
                UNIXUSER=slroms1
        elif [[ "${PRODUCT}" = "slrams" ]]
        then
                UNIXUSER=slrams1
        elif [[ "${PRODUCT}" = "omni" ]] 
				then
				UNIXUSER=omnwrk1
        else
                UNIXUSER=${PRODUCT}wrk1
        fi
fi

if [[ "${PHASE}" = "TRN" ]]
then
case ${PRODUCT} in
        enb)
                UNIXUSER=trnabp${ENV_NUMBER}
                PRODUCT='enb'
                ;;
        amss)
                UNIXUSER=trnmcs${ENV_NUMBER}
                ;;
        slroms)
                UNIXUSER=trnslo${ENV_NUMBER}
                ;;
        slrams)
                UNIXUSER=trnsla${ENV_NUMBER}
                ;;
		omni)
                UNIXUSER=trnomn${ENV_NUMBER}
                ;;
        *)
                UNIXUSER=trn${PRODUCT}${ENV_NUMBER}
                ;;
esac
fi

#FindUnixBox ${ENV_NUMBER} ${PRODUCT} ${VERSION} ${PHASE}

if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} ${PRODUCT} ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} ${PRODUCT} ${VERSION} ${PHASE}
fi


case $1 in
        ABP)    SERVER_STATUS=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ; cd ${abpScriptPath} ; ${abpPingScript}"`
                ;;
        CRM)    SERVER_STATUS=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ; cd ${crmScriptPath} ; ./${crmPingScript}"`
                ;;
        OMS)    SERVER_STATUS=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ; cd ${omsScriptPath} ; ./${omsPingScript}"`
       			;; 
        SLROMS)    SERVER_STATUS=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ; cd ${slrScriptPath} ; ./${slrPingScript}" `
               	;;
        SLRAMS)    SERVER_STATUS=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ; cd ${slraScriptPath} ; ./${slraPingScript}" `
               	;;
		AMSS)	
		SERVER_STATUS=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ; cd ${amssScriptPath} ; ./${amssPingScript}" | cut -d" " -f1`
		AMSS_SERVER_STATUS=`echo $SERVER_STATUS`
				;;
		OMNI)	
		SERVER_STATUS=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ; cd ${omniScriptPath} ; ./${omniPingScript}" | cut -d" " -f1`
		OMNI_SERVER_STATUS=`echo $SERVER_STATUS`
				;;
	*)      echo "please give product Name"
                exit 1
                ;;
esac

echo "<tr>"
echo "<td bgcolor='4BACC6'> <b> `echo ${PRODUCT} | tr '[a-z]' '[A-Z]'` </b> </td> "
if [ "${SERVER_STATUS}" == "DOWN" ]
then
    echo "<td bgcolor='red'> DOWN </td>"
else
    echo "<td bgcolor='04B404'> UP </td>"
fi

LOG_STATUS=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ; ${SCRIPTHOMEDIR}/checkWebLogicLog.ksh ${PRODUCT}"`
    if [ "$?" == "0" ]
    then
        echo "<td bgcolor='04B404'> ${LOG_STATUS} </td>"
    else
        echo "<td bgcolor='yellow'> ${LOG_STATUS} </td>"
    fi

echo "	</tr> "

}


#################################################################
#
#showDaemonStatus
#
#################################################################
showDaemonStatus()
{

DAEMONNAME=${1}
findExe=${2}

if [[ "${PHASE}" = "CST" ]]
then
UNIXUSER=abpwrk1
elif [[ "${PHASE}" = "TRN" ]]
then
UNIXUSER=trnabp${ENV_NUMBER}
else
#UNIXUSER=${PROJ_ABBR}wrk${ENV_NUMBER}
UNIXUSER=${PROJ_ABBR}abp${ENV_NUMBER}
fi

#FindUnixBox ${ENV_NUMBER} enb ${VERSION} ${PHASE}

if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} enb ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} enb ${VERSION} ${PHASE}
fi

st=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ; ps -fu ${UNIXUSER} | grep '${findExe}' |grep -v grep |wc -l"`

if [ "`expr ${ROWNUMBER} % 2 `" == "0" ]
then
        echo "<tr bgcolor='A5D5E2'>"
else
        echo "<tr bgcolor='D2EAF1'>"
fi
echo "<td> <b> ${DAEMONNAME} </b> </td>"
if [ $st -ne 1 ]
then
     echo " <td bgcolor='red'> DOWN </td>"
else
     echo " <td bgcolor='04B404'> UP </td>"
fi
echo "	</tr>"

ROWNUMBER=`expr ${ROWNUMBER} + 1`
}

showControl_MStatus()
{

if [[ "${PHASE}" = "CST" ]]
then
UNIXUSER=abpwrk1
elif [[ "${PHASE}" = "TRN" ]]
then
UNIXUSER=trnabp${ENV_NUMBER}
else
#UNIXUSER=${PROJ_ABBR}wrk${ENV_NUMBER}
UNIXUSER=${PROJ_ABBR}abp${ENV_NUMBER}
fi

#FindUnixBox ${ENV_NUMBER} enb ${VERSION} ${PHASE}

if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} enb ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} enb ${VERSION} ${PHASE}
fi

if [ "${HOST}" = "indlin3662" ]
then
st=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;rm -f Output; /opt/controlm/ctmsrv/ctm_agent/ctm/scripts/ag_diag_comm | grep Succeeded >> Output; /opt/controlm/ctmsrv/ctm_agent/ctm/scripts/ag_diag_comm | grep  Running  >> Output;cat Output | wc -l  "`
else
st=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;rm -f Output; /opt/controlm/ctm/scripts/ag_diag_comm | grep Succeeded >> Output; /opt/controlm/ctm/scripts/ag_diag_comm | grep  Running  >> Output;cat Output | wc -l  "`
fi

if [ "`expr ${ROWNUMBER} % 2 `" == "0" ]
then
        echo "<tr bgcolor='A5D5E2'>"
else
        echo "<tr bgcolor='D2EAF1'>"
fi
echo "<td> <b> ControlM </b> </td>"
if [ "$st" == "5"  ] 
then
     echo " <td bgcolor='04B404'> UP </td>"

else
     echo " <td bgcolor='red'> DOWN </td>"
fi
echo "  </tr>"

ROWNUMBER=`expr ${ROWNUMBER} + 1`
}


########################################################################
#
#showProductHfs
#
#################################################################
showProductHfs()
{

PRODUCT=`echo ${1} | tr '[A-Z]' '[a-z]'`
UNIXUSER=""
UNIXBOX=""

case ${PRODUCT} in
        abp)
                #UNIXUSER=${PROJ_ABBR}wrk${ENV_NUMBER}
                UNIXUSER=${PROJ_ABBR}abp${ENV_NUMBER}
                PRODUCT='enb'
                ;;
        amss)
                UNIXUSER=vivmcs${ENV_NUMBER}
                ;;
        slroms)
                UNIXUSER=vivslo${ENV_NUMBER}
                ;;
        slrams)
                UNIXUSER=vivsla${ENV_NUMBER}
                ;;
        *)
                UNIXUSER=${PROJ_ABBR}${PRODUCT}${ENV_NUMBER}
                ;;
esac

if [[ "${PHASE}" = "CST" ]]
then
        if [[ "${PRODUCT}" = "enb" ]]
        then
                UNIXUSER=abpwrk1
        elif [[ "${PRODUCT}" = "amss" ]]
        then
                UNIXUSER=amswrk1
        elif [[ "${PRODUCT}" = "slroms" ]]
        then
                UNIXUSER=slroms1
        elif [[ "${PRODUCT}" = "slrams" ]]
        then
                UNIXUSER=slrams1
        else
                UNIXUSER=${PRODUCT}wrk1
        fi
fi

if [[ "${PHASE}" = "TRN" ]]
then
case ${PRODUCT} in
        abp)
                UNIXUSER=trnabp${ENV_NUMBER}
                PRODUCT='enb'
                ;;
        amss)
                UNIXUSER=trnmcs${ENV_NUMBER}
                ;;
        slroms)
                UNIXUSER=trnslo${ENV_NUMBER}
                ;;
        slrams)
                UNIXUSER=trnsla${ENV_NUMBER}
                ;;
        *)
                UNIXUSER=trn${PRODUCT}${ENV_NUMBER}
                ;;
esac
fi

#FindUnixBox ${ENV_NUMBER} ${PRODUCT} ${VERSION} ${PHASE}

if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} ${PRODUCT} ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} ${PRODUCT} ${VERSION} ${PHASE}
fi

if [[ "${PHASE}" = "CST" ]]
then
hflist=`sqlplus -s ${AMCDBString} << EOF
set hea off feed off pagesize 0
select unique unique_id 
from   HOTFIX_EVT 
where  ENVIRONMENT   = '${UNIXUSER}@${UNIXBOX}' 
and    EVENT_NAME    = 'DEPLOYED'; 
exit;
EOF`
else
hflist=`sqlplus -s ${AMCDBString} << EOF
set hea off feed off pagesize 0
select unique unique_id 
from   HOTFIX_EVT 
where  ENVIRONMENT   = '${UNIXUSER}@${UNIXBOX}' 
and    EVENT_NAME    = 'DEPLOYED' 
and    CREATION_DATE >= (select REFRESH_DATE 
                         from   HOTFIX_ENVIRONMENTS 
                         where  ENVIRONMENT = '${UNIXUSER}@${UNIXBOX}');
exit;
EOF`

fi

for hf_number in ${hflist}
do
    if [ "`expr ${ROWNUMBER} % 2 `" == "0" ]
    then
        echo "<tr bgcolor='A5D5E2'>"
    else
        echo "<tr bgcolor='D2EAF1'>"
    fi
    echo "<td> `echo ${PRODUCT} | tr '[a-z]' '[A-Z]'` </td>" 
    echo "<td> ${hf_number} </td>"
    echo "</tr>"
    ROWNUMBER=`expr ${ROWNUMBER} + 1`
done

}

########################################################################
#
#showABPURLInformation
#
#################################################################
showABPURLInformation()
{

if [[ "${PHASE}" = "CST" ]]
then
UNIXUSER=abpwrk1
elif [[ "${PHASE}" = "TRN" ]]
then
UNIXUSER=trnabp${ENV_NUMBER}
else
#UNIXUSER=${PROJ_ABBR}wrk${ENV_NUMBER}
UNIXUSER=${PROJ_ABBR}abp${ENV_NUMBER}
fi

#FindUnixBox ${ENV_NUMBER} enb ${VERSION} ${PHASE}

if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} enb ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} enb ${VERSION} ${PHASE}
fi

ssh -q ${UNIXUSER}@${UNIXBOX} -n " . ./.profile >/dev/null 2>&1 ; ${SCRIPTHOMEDIR}/showABPURLInformation.ksh "

}
########################################################################
#
#showEnvironmentIntegrationDetails
#
#################################################################
showEnvironmentIntegrationDetails()
{

if [[ "${PHASE}" = "CST" ]]
then
UNIXUSER=omswrk1
elif [[ "${PHASE}" = "TRN" ]]
then
UNIXUSER=trnoms${ENV_NUMBER}
else
UNIXUSER=${PROJ_ABBR}oms${ENV_NUMBER}
fi

#FindUnixBox ${ENV_NUMBER} oms ${VERSION} ${PHASE}

if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} oms ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} oms ${VERSION} ${PHASE}
fi

ssh ${UNIXUSER}@${UNIXBOX} ". ./.profile >/dev/null 2>&1 ; ${SCRIPTHOMEDIR}/showIntegrationValuesHtml.ksh "
}
#####################################################
#
#	List of hfs deployed on the environment
#
#
#######################################################

showEnvionmentHF()
{
UNIXBOX=""
HF_ENVIRONMENTS=""
if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} ${PRODUCT} ${VERSION} ${PHASE}
    HF_ENVIRONMENTS="'abpwrk1@${UNIXBOX}','crmwrk1@${UNIXBOX}','omswrk1@${UNIXBOX}','amswrk1@${UNIXBOX}','slrams1@${UNIXBOX}','slroms1@${UNIXBOX}','omnwrk1@${UNIXBOX}','wsfwrk1@${UNIXBOX}'"
elif [[ "${PHASE}" = "TRN" ]]
then
    FindUnixBoxOther ${ENV_NUMBER} enb ${VERSION} ${PHASE}
    HF_ENVIRONMENTS="'trnabp${ENV_NUMBER}@${UNIXBOX}',"
    FindUnixBoxOther ${ENV_NUMBER} crm ${VERSION} ${PHASE}
    HF_ENVIRONMENTS=${HF_ENVIRONMENTS}"'trncrm${ENV_NUMBER}@${UNIXBOX}',"
    FindUnixBoxOther ${ENV_NUMBER} oms ${VERSION} ${PHASE}
    HF_ENVIRONMENTS=${HF_ENVIRONMENTS}"'trnoms${ENV_NUMBER}@${UNIXBOX}',"
    FindUnixBoxOther ${ENV_NUMBER} amss ${VERSION} ${PHASE}
    HF_ENVIRONMENTS=${HF_ENVIRONMENTS}"'trnmcs${ENV_NUMBER}@${UNIXBOX}',"
    FindUnixBoxOther ${ENV_NUMBER} slroms ${VERSION} ${PHASE}
    HF_ENVIRONMENTS=${HF_ENVIRONMENTS}"'trnslo${ENV_NUMBER}@${UNIXBOX}',"
    FindUnixBoxOther ${ENV_NUMBER} enb ${VERSION} ${PHASE}
    HF_ENVIRONMENTS=${HF_ENVIRONMENTS}"'trnsla${ENV_NUMBER}@${UNIXBOX}'"

else
    FindUnixBoxOther ${ENV_NUMBER} enb ${VERSION} ${PHASE}
    HF_ENVIRONMENTS="'${PROJ_ABBR}abp${ENV_NUMBER}@${UNIXBOX}',"
    FindUnixBoxOther ${ENV_NUMBER} crm ${VERSION} ${PHASE}
    HF_ENVIRONMENTS=${HF_ENVIRONMENTS}"'${PROJ_ABBR}crm${ENV_NUMBER}@${UNIXBOX}',"
    FindUnixBoxOther ${ENV_NUMBER} oms ${VERSION} ${PHASE}
    HF_ENVIRONMENTS=${HF_ENVIRONMENTS}"'${PROJ_ABBR}oms${ENV_NUMBER}@${UNIXBOX}',"
    FindUnixBoxOther ${ENV_NUMBER} amss ${VERSION} ${PHASE}
    HF_ENVIRONMENTS=${HF_ENVIRONMENTS}"'${PROJ_ABBR}mcs${ENV_NUMBER}@${UNIXBOX}',"
    FindUnixBoxOther ${ENV_NUMBER} slroms ${VERSION} ${PHASE}
    HF_ENVIRONMENTS=${HF_ENVIRONMENTS}"'${PROJ_ABBR}slo${ENV_NUMBER}@${UNIXBOX}',"
    FindUnixBoxOther ${ENV_NUMBER} enb ${VERSION} ${PHASE}
    HF_ENVIRONMENTS=${HF_ENVIRONMENTS}"'${PROJ_ABBR}sla${ENV_NUMBER}@${UNIXBOX}'"
fi
spoolfile=/tmp/HF_List$$.txt
if [ -f ${spoolfile} ]
then
	rm ${spoolfile}
fi
if [ ! -z ${BUNDLENAMES} ]
then
HFBUNDLESTRING=`echo ${BUNDLENAMES} | sed "s#,#','#g"`
##################################################################
# below block for to get the list of the HFs of Bundle deployed.
##################################################################
		hflist=`sqlplus -s ${AMCDBString} << EOF
		set hea off feed off pagesize 0 linesize 500 
		col name format a60
		spool ${spoolfile}
		select unique HOTFIX_MNG.UNIQUE_ID,HOTFIX_MNG.PRODUCT,HOTFIX_EVT.EVENT_NAME,HOTFIX_EVT.ENVIRONMENT,HOTFIX_BUNDLES.BUNDLE_NAME from HOTFIX_EVT, HOTFIX_BUNDLES, HOTFIX_MNG   
		where HOTFIX_BUNDLES.UNIQUE_ID = HOTFIX_EVT.UNIQUE_ID 
		and HOTFIX_MNG.UNIQUE_ID = HOTFIX_EVT.UNIQUE_ID
		and HOTFIX_BUNDLES.BUNDLE_NAME in ('${HFBUNDLESTRING}') 
		and HOTFIX_EVT.ENVIRONMENT in (${HF_ENVIRONMENTS}) and not HOTFIX_EVT.UNIQUE_ID in (select UNIQUE_ID from HOTFIX_EVT where EVENT_NAME = 'FAILED' and ENVIRONMENT in (${HF_ENVIRONMENTS}));
		spool off
		exit;
		EOF` 
		while read hotfixid prod status environment bundlename 
		do
			 if [ "`expr ${ROWNUMBER} % 2 `" == "0" ]
		    then
		        echo "<tr bgcolor='A5D5E2'>"
		    else
		        echo "<tr bgcolor='D2EAF1'>"
		    fi
			echo "<td> $hotfixid </td> <td> $prod</td> <td> $environment</td> <td> $bundlename</td> <td> $status</td> "
			
			echo "</tr>"
		  ROWNUMBER=`expr ${ROWNUMBER} + 1`
		done < ${spoolfile}
		rm ${spoolfile}


######################################################################
#below block for to get the list of the HFs of Bundle failed.
#
######################################################################
 hflist=`sqlplus -s ${AMCDBString} << EOF
        set hea off feed off pagesize 0 linesize 500
        col name format a60
        spool ${spoolfile}
        select unique HOTFIX_MNG.UNIQUE_ID,HOTFIX_MNG.PRODUCT,HOTFIX_EVT.EVENT_NAME,HOTFIX_EVT.ENVIRONMENT,HOTFIX_BUNDLES.BUNDLE_NAME from HOTFIX_EVT, HOTFIX_BUNDLES, HOTFIX_MNG
        where HOTFIX_BUNDLES.UNIQUE_ID = HOTFIX_EVT.UNIQUE_ID
        and HOTFIX_MNG.UNIQUE_ID = HOTFIX_EVT.UNIQUE_ID
        and HOTFIX_BUNDLES.BUNDLE_NAME in ('${HFBUNDLESTRING}')
        and HOTFIX_EVT.ENVIRONMENT in (${HF_ENVIRONMENTS}) 
		and HOTFIX_EVT.EVENT_NAME='FAILED';
        spool off
        exit;
        EOF`
        while read hotfixid prod status environment bundlename
        do
                echo "<tr bgcolor='RED'>"
            echo "<td> $hotfixid </td> <td> $prod</td> <td> $environment</td> <td> $bundlename</td> <td> $status</td> "

            echo "</tr>"
          ROWNUMBER=`expr ${ROWNUMBER} + 1`
        done < ${spoolfile}
        rm ${spoolfile}
######################################################################
#below block for to get the list of the HFs of Bundle Not even deployed.
#
######################################################################
hflist=`sqlplus -s ${AMCDBString} << EOF
        set hea off feed off pagesize 0 linesize 500
        col name format a60
        spool ${spoolfile}
		select unique HOTFIX_MNG.UNIQUE_ID,HOTFIX_MNG.PRODUCT from HOTFIX_MNG, HOTFIX_BUNDLES 
where HOTFIX_BUNDLES.BUNDLE_NAME in ('${HFBUNDLESTRING}')
and HOTFIX_BUNDLES.UNIQUE_ID = HOTFIX_MNG.UNIQUE_ID
and HOTFIX_MNG.UNIQUE_ID not in ( select UNIQUE_ID from HOTFIX_EVT where ENVIRONMENT in (${HF_ENVIRONMENTS}));
        spool off
        exit;
        EOF`
        while read hotfixid prod status environment bundlename
        do
           echo "<tr bgcolor='YELLOW'> <td> $hotfixid </td> <td> $prod</td> <td> $environment</td> <td> $bundlename</td> <td> NOT DEPLOYED/Manual HF</td> </tr> "
        done < ${spoolfile}
        rm ${spoolfile}

##################################################################################
#below block for to get the list of the HFs of which are not part of Bundle .
#
##################################################################################
		hflist=`sqlplus -s ${AMCDBString} << EOF
		set hea off feed off pagesize 0 linesize 500 
		col name format a60
		spool ${spoolfile}
		select unique HOTFIX_MNG.UNIQUE_ID,HOTFIX_MNG.PRODUCT,HOTFIX_EVT.EVENT_NAME,HOTFIX_EVT.ENVIRONMENT from HOTFIX_EVT,HOTFIX_MNG   
		where HOTFIX_MNG.UNIQUE_ID = HOTFIX_EVT.UNIQUE_ID
		and HOTFIX_EVT.ENVIRONMENT   in  (${HF_ENVIRONMENTS}) 
		and not HOTFIX_EVT.UNIQUE_ID in (select UNIQUE_ID from HOTFIX_EVT where EVENT_NAME = 'FAILED' and ENVIRONMENT in (${HF_ENVIRONMENTS})) 
		and HOTFIX_MNG.UNIQUE_ID not in ( select UNIQUE_ID from HOTFIX_BUNDLES where HOTFIX_BUNDLES.BUNDLE_NAME in ('${HFBUNDLESTRING}'));
		spool off
		exit;
		EOF`
		while read hotfixid prod status environment
		do
			 if [ "`expr ${ROWNUMBER} % 2 `" == "0" ]
		    then
		        echo "<tr bgcolor='A5D5E2'>"
		    else
		        echo "<tr bgcolor='D2EAF1'>"
		    fi
			if [ "$status" = "FAILED" ]
            then
                echo "</tr><tr bgcolor='RED'>"
            fi

			echo "<td> $hotfixid </td> <td> $prod </td> <td> $environment </td> <td> </td> <td>  $status </td>"
			echo "</tr>"
		  ROWNUMBER=`expr ${ROWNUMBER} + 1`	
		done < ${spoolfile}
		rm ${spoolfile}
else
	hflist=`sqlplus -s ${AMCDBString} << EOF
		set hea off feed off pagesize 0 linesize 500 
		col name format a60
		spool ${spoolfile}
		select unique HOTFIX_MNG.UNIQUE_ID,HOTFIX_MNG.PRODUCT,HOTFIX_EVT.EVENT_NAME,HOTFIX_EVT.ENVIRONMENT from HOTFIX_EVT,HOTFIX_MNG   
		where HOTFIX_MNG.UNIQUE_ID = HOTFIX_EVT.UNIQUE_ID and not EVENT_NAME like 'FAILED'
		and HOTFIX_EVT.ENVIRONMENT   in  (${HF_ENVIRONMENTS})
        and HOTFIX_EVT.CREATION_DATE >= (select max(REFRESH_DATE) from HOTFIX_ENVIRONMENTS where ENVIRONMENT in (${HF_ENVIRONMENTS}));
		spool off
		exit;
		EOF`
		while read hotfixid prod status environment
		do
			 if [ "`expr ${ROWNUMBER} % 2 `" == "0" ]
		    then
		        echo "<tr bgcolor='A5D5E2'>"
		    else
		        echo "<tr bgcolor='D2EAF1'>"
		    fi
			if [ "$status" = "FAILED" ]
            then
                echo "</tr><tr bgcolor='RED'>"
            fi

			echo "<td> $hotfixid </td> <td> $prod </td>  <td> $environment </td> <td>  $status </td>"
			echo "</tr>"
		  ROWNUMBER=`expr ${ROWNUMBER} + 1`	
		done < ${spoolfile}
		rm ${spoolfile}
fi
}


########################################################################
#
#generateEmailContent
#
#################################################################
generateEmailContent()
{
echo "<html>"
echo "<body>"
echo "Hi All," 
echo "<br>"
echo "<br>"
echo "<strong> <em> <h2> ICM Environment ${PHASE} #${ENV_NUMBER} refreshed successfully with the following details: </strong> </em> </h2>"
echo "<br>"
if [[ "${IS_GOLDEN}" = "Y" ]]
then
	echo "<strong> <em> <h3> *** Please note that for BootManager and EnSight the environment code name is same as Server name </strong> </em> </h3>"
	echo "<br>"
fi
echo "<b> <u>General Information:</u> </b> "
ROWNUMBER=0
echo "<table border='1' > <b>"
echo "<tr bgcolor='4BACC6'>"
echo "  <td> Product </td>"
echo "  <td> URL Details  </td>"
echo "  <td> Login  Details</td>"
echo "</tr> </b>"

  showGeneralInformation
  #showCRMSmartClientDetails crm
  showProductsDetails
echo "</table>"
echo "<br>"
echo "<br>"
echo "<b> <u>ICM Environment Details:</u> </b> "
ROWNUMBER=0
echo "<table border='1' > <b>"
echo "<tr bgcolor='4BACC6'>"
echo "	<td> Product </td>"
echo "	<td> User/Password </td>"
echo "	<td> Server </td>"
echo "	<td> Storage Details </td>"
echo "</tr> </b>"

  showEnvironmentDetails ABP 
  showEnvironmentDetails CRM 
  showEnvironmentDetails OMS 
  showEnvironmentDetails SLROMS 
  showEnvironmentDetails SLRAMS 
  showEnvironmentDetails AMSS 
  showEnvironmentDetails OMNI
  showEnvironmentDetails WSF
echo "</table>"


ROWNUMBER=0
echo "<br>"
echo "<br>"
echo "<b> <u>Products Dumps Information:</u> </b> "
echo "<table border='1' > <b>"
echo "<tr bgcolor='4BACC6'>"
echo "  <td> Product &nbsp;&nbsp;</td>"
echo "  <td> Patch NO. &nbsp;&nbsp;</td>"
echo "  <td> DMP Type </td>"
echo "  <td> DMP Full Path </td>"
echo "</tr> </b>"
showEnvironmentDumps 
echo "</table>"

#echo "<b> <u>Integration With Other Modules:</u> </b>"

#  showEnvironmentIntegrationDetails
  showABPURLInformation
ROWNUMBER=0
echo "<br>"
echo "<br>"
echo "<div>"
echo "<b> <u>Servers Status:</u> </b> "
echo "<table border='1'> <b> "
echo "	<tr bgcolor='4BACC6'>"
echo "		<td> Product </td>"
echo "		<td> Status </td>"
echo "		<td> Exception in Startup </td>"	
echo "	</tr> </b>"

	showServerStatus ABP 
	showServerStatus CRM 
	showServerStatus OMS 
	showServerStatus SLROMS
	showServerStatus SLRAMS
	showServerStatus AMSS 
	showServerStatus OMNI
echo "</table>"
echo "</div>"

echo "<br>"
echo "<br>"

ROWNUMBER=0
echo "<div>"
echo "<b> <u>Daemons Status:</u> </b>"
echo "<table border='1'> <b> "
echo "	<tr bgcolor='4BACC6'>"
echo "		<td> Daemon Name </td>"
echo "		<td> Status </td>"
echo "	</tr> </b>"
    showControl_MStatus 
	showDaemonStatus "amc1_DaemonManager"    "amc1_DmnEnvelope DmnMng"
	showDaemonStatus "ACIMANAGER"            "Ac1FtcManager"
	showDaemonStatus "TRB1ENGINE_1"          "TRB1Manager"
	showDaemonStatus "OP1MRO_1"              "amc_mro"
	showDaemonStatus "TLS1_APInvoker_1_1"    'amc1_DmnEnvelope TLS1_APInvoker_1_1'
	showDaemonStatus "TLS1_APInvoker_10_1"   'amc1_DmnEnvelope TLS1_APInvoker_10_1'
	showDaemonStatus "BL1BTLSOR"             "BL1BTLSOR"
	showDaemonStatus "BTLQUOTE"              "BTLQUOTE"
	showDaemonStatus "DB2E1502"              "DB2E1502"
	showDaemonStatus "DB2E1504"              "DB2E1504"
        showDaemonStatus "ES_FR1224"             "ES_FR1224"
        #showDaemonStatus "ES_FR1226"             "ES_FR1226"
        showDaemonStatus "ES_RB1216"               "ES_RB1216"
        #showDaemonStatus "ES_RB1218"             "ES_RB1218"
        #showDaemonStatus "ES_RB1223"               "ES_RB1223"
		showDaemonStatus "F2E1233" "F2E1233"
        showDaemonStatus "NTF1276"               "NTF1276"
		showDaemonStatus "UQ_SERVER1257" "UQ_SERVER1257"
  showDaemonStatus "Core" "ASMMBSS//Core/bin/xwd" 
   showDaemonStatus "G1_PROCESSING1" "ASMMBSS/G1_PROCESSING1/bin/xwd"
   showDaemonStatus "G2_PROCESSING2" "ASMMBSS/G2_PROCESSING2/bin/xwd"
   showDaemonStatus "G3_PROCESSING3" "ASMMBSS/G3_PROCESSING3/bin/xwd"
   showDaemonStatus "G4_PROCESSING4" "ASMMBSS/G4_PROCESSING4/bin/xwd"

	
echo "</table>"
echo "</div>"

echo "<br>"
echo "<br>"
ROWNUMBER=0
echo "<div>"
echo "<b> <u>List of HF's Applied: </u></b>"
echo "<table border='1'> <b> "
echo '<tr  bgcolor="4BACC6">'
echo "<td> Hotfix Number </td>"
echo "<td> Product </td>"
echo "<td> Environment </td>"
if [ ! -z ${BUNDLENAMES} ]
then
echo  "<td> Bundle Name </td>"
fi
echo "<td> Status </td>"
echo "</tr> </b>"
	showEnvionmentHF
echo "</table>"
echo "</div>"
echo "<br>"
echo "<br>"
ROWNUMBER=0

echo "<div>"
echo "</div>"
echo "</div>"
echo "<div>"
echo "Regards," 
echo "<br>"
echo "${TEAM}"
echo "</div>"
echo "</body>"
echo "</html>"

}

########################################################################
#
#prepareEmailContent
#
#################################################################

prepareEmailContent()
{
echo "From:${EMAIL_FROM} "
echo "To:${EMAIL_TO}"
echo "Cc:${EMAIL_CC}"
echo "Subject:${EMAIL_SUBJECT}"

echo "Content-Type: text/html; charset=\"us-ascii\""

generateEmailContent
}

####################################################################
#
# Main Function starts from here
#
#################################################################
IS_GOLDEN="N"

	if [ $# -lt 3 ]
	then
    		print "\n\tUSAGE : `basename $0` <Env Num(ST)|Env VM Id(CST)> <Version> <Phase> <Project> [<GOLDEN>] [HFBUNDLENAME]\n"
                print "\tSample : `basename $0`  10 3000 ST VIVO \n"
                print "\tSample : `basename $0`  331 3000 CST VIVO GOLDEN \n"
				print "\tSample : `basename $0`  331 3000 CST VIVO GOLDEN HFBUNDLENAME\n"
    		exit 1
	fi

ENV_NUMBER=${1}
VERSION=${2}
PHASE=${3}
PROJECT=${4}
SWP=`echo ${5} | tr -cd '[:digit:]'`
BUNDLENAMES=${6}

if [ "${SWP}" = "GOLDEN" ]
then
	IS_GOLDEN="Y"
fi

if [ "${PHASE}" = "UAT" -o "${PHASE}" = "TRN" ]
then
   if [ "${HOST}" = "indlin3662" ] 
   then
     ssh amdocs@10.33.200.219 "ssh vivtools@vlty0532sl ' . ./.profile >/dev/null 2>&1 ; cd /vivnas/viv/vivtools/Scripts; GenerateEnvReleaseMail.ksh ${ENV_NUMBER} ${VERSION} ${PHASE} ${PROJECT} '" | /usr/sbin/sendmail -t
     exit 0
   fi
fi

variableDefinition
if [[ "${PHASE}" = "CST" ]]
then
UNIXUSER=crmwrk1
elif [[ "${PHASE}" = "TRN" ]]
then
UNIXUSER=trncrm${ENV_NUMBER}
else
UNIXUSER=${PROJ_ABBR}crm${ENV_NUMBER}
fi

#FindUnixBox ${ENV_NUMBER} crm ${VERSION} ${PHASE}

if [[ "${PHASE}" = "CST" ]]
then
    FindUnixBox ${ENV_NUMBER} crm ${VERSION} ${PHASE}
else
    FindUnixBoxOther ${ENV_NUMBER} crm ${VERSION} ${PHASE}
fi


export crm_version=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd .xpi/repository/topologies; grep ST_CRM * 2>/dev/null |cut -d"/" -f5 | cut -d "_" -f3 | sed "s/V//" | uniq "`
export crm_build_number=`ssh -q ${UNIXUSER}@${UNIXBOX} -n ". ./.profile >/dev/null 2>&1 ;cd .xpi/repository/topologies; grep ST_CRM * 2>/dev/null | cut -d"/" -f5 | cut -d "_" -f4 | sed "s/B//" | uniq"`


ICM_BUILD=`grep "ICM.build.number" /XPISTORAGE/${crm_version}/CRM/ST_CRM_V${crm_version}_B${crm_build_number}/packages/crm_build.number | cut -d '=' -f2 | head -1`

#ICM_BUILD=`ssh -q ${UNIXUSER}@${UNIXBOX} -n " . ./.profile 2>/dev/null | grep 'The ICM build number in this environment' | cut -d ':' -f2"`
typeset -i i_ICM=${ICM_BUILD}
if [[ "${IS_GOLDEN}" = "N" ]]
then
	EMAIL_SUBJECT="VIVO V${VERSION} SWP#${i_ICM} ICM Build#${i_ICM} Env #${ENV_NUMBER} - Release Environment Report"
else
	EMAIL_SUBJECT="VIVO V${VERSION} SWP#${i_ICM} ICM Build#${i_ICM} Env #${ENV_NUMBER} - Release IaaS Golden Environment Report"
fi

#prepareEmailContent
if [ "${HOST}" = "indlin3662" ] 
then
prepareEmailContent | /usr/sbin/sendmail -t
else
prepareEmailContent
fi
#prepareEmailContent > tempmail.html

exit 0
