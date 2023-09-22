#!/bin/ksh -xv

#######################INIT SECTION###############################################################
#
#   Supervisor:   Slavik Leibovich
#
#   NAME :        Delivery
#
#   DESCRIPTION : The script will perform the following
#                 Packs the jars to tar files, Delivery packages .
#
#                 
#   USAGE       : BSS_Delivery.ksh <Version> <Delivery_link> <account> <server>
#
#   DATE        : 10-07-2014
#
##################################################################################################


###################### Initialization Area - Start ###############################################

Version=$1
#Version is the CC version
Delivery_link=$2
#Delivery link shoudl be with full path
Account=$3
#Account is the ABP account of the environment that was delivered in the SWP
Server=$4
#Server is the ABP Server of the environment that was delivered in the SWP
ABP_BN=$5
CRM_BN=$6
OMS_BN=$7
AMSS_BN=$8
SLRAMS_BN=$9
SLROMS_BN=$10
EPC_BN=$11
WSF_BN=$12
APRM_BN=$13
GENESIS_HOME=/bssxpinas/bss/tooladm
INF_TOOLS_DB_USER=tooladm
INF_TOOLS_DB_PASS=tooladm
INF_TOOLS_DB_INST=BS9INF
Reader_Server=bssdlv@illin1339
Writer_Server=bssdel@illin1339

###################### Initialization Area - End  ################################################


####################### variable #################################################################

if [ $# -ne 13 ]
then
     print "\n\tUSAGE : `basename $0` <Version> <Delivery_link> <Account> <Server> <ABP_BN CRM_BN OMS_BN AMSS_BN SLRAMS_BN SLROMS_BN EPC_BN WSF_BN APRM_BN"
     exit 1
fi

##################################################################################################


###################### Create directories and link ###############################################

ssh $Writer_Server -n "rm ${Delivery_link}/INT ; mkdir -p ${Delivery_link}/INT"
link_name=`echo ${Delivery_link} |awk -F"\/" '{print $NF}'`
ssh $Reader_Server -n "cd /bssdlvhome/bss/dlv/bssdlv ;rm -f ${link_name}; ln -s ${Delivery_link} ."

for PRODUCT in ABP CRM OMS AMSS SLRAMS SLROMS EPC WSF PRM
do
	ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/$PRODUCT; mkdir -p ${Delivery_link}/INT/$PRODUCT"
        CC_VARIANT=64OG
        if [[ "$PRODUCT" = "ABP" || "$PRODUCT" = "APRM" ]]
        then
           CC_VARIANT=64
        fi
        if [[ "$PRODUCT" = "SLROMS" || "$PRODUCT" = "SLRAMS" || "$PRODUCT" = "EPC" ]]
        then
           CC_VARIANT=""
        fi
        BN_PATH_TMP1=`echo ${PRODUCT}"_BN"`
        BN_PATH_TMP2=`eval echo "$"$BN_PATH_TMP1`
        BN_PATH=`echo "BN_"$BN_PATH_TMP2`
        cd /XPISTORAGE/BUILD_RELEASE/$PRODUCT/v${Version}/$CC_VARIANT/$BN_PATH
        ls -l | grep XPISTORAGE | awk '{print $11}' > Core_files_list
        ls -l | grep XPISTORAGE | awk '{print $9}' > Core_files_links_list
	ls -l | grep -v lrwx | grep jar | awk '{print $9}' > Custom_file_list
        ls amdocs*.tar >> Custom_file_list
        ls *build.number >> Custom_file_list
        if [[ "$PRODUCT" != "SLROMS" && "$PRODUCT" != "SLRAMS" && "$PRODUCT" != "WSF" && "$PRODUCT" != "PRM" ]]
        then
   	   ls Portfoli*.properties >> Custom_file_list
	   ls XDK/*  >> Custom_file_list
        fi
	tar -cvf ${PRODUCT}_core_pacakges.tar -T Core_files_list --absolute-names --dereference
	gzip ${PRODUCT}_core_pacakges.tar 
	tar -cvf ${PRODUCT}_links.tar -T Core_files_links_list
	tar -cvf ${PRODUCT}_custom_packages.tar -T Custom_file_list
	gzip ${PRODUCT}_custom_packages.tar 
	ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/Packages/${PRODUCT}"
	scp ${PRODUCT}_core_pacakges.tar.gz ${Writer_Server}:${Delivery_link}/INT/Packages/${PRODUCT}
	scp ${PRODUCT}_links.tar ${Writer_Server}:${Delivery_link}/INT/Packages/${PRODUCT}
	scp ${PRODUCT}_custom_packages.tar.gz ${Writer_Server}:${Delivery_link}/INT/Packages/${PRODUCT}
	rm -f Core_files_list
	rm -f Core_files_links_list
	rm -f Custom_file_list
	rm -f ${PRODUCT}_core_pacakges.tar.gz
	rm -f ${PRODUCT}_links.tar 
	rm -f ${PRODUCT}_custom_packages.tar.gz 
        if [[ "$PRODUCT" = "AMSS" ]]
        then
           cd /XPISTORAGE/CORE/AMSS/$CC_VARIANT
           AMSS_JAVA_SEC_FILE=`ls JAVA*`
           scp ${AMSS_JAVA_SEC_FILE} ${Writer_Server}:${Delivery_link}/INT/Packages/${PRODUCT}
        fi
        if [[ "$PRODUCT" = "OMS" ]]
        then
           cd /XPISTORAGE/CORE/OMS_REPO/ANT-CONTRIB
           OMS_ANT_CONTRIB_FILE=`ls ant-contrib-1*`
           scp ${OMS_ANT_CONTRIB_FILE} ${Writer_Server}:${Delivery_link}/INT/Packages/${PRODUCT}
        fi
        if [[ "$PRODUCT" = "ABP" ]]
        then
           cd /XPISTORAGE/CORE/ABP_REPO
           scp PF_FOR_AMF.tar ${Writer_Server}:${Delivery_link}/INT/Packages/${PRODUCT}
        fi
done

############ MCO.tar ############################################################################

ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/MCO; mkdir -p ${Delivery_link}/INT/MCO"
cd /XPISTORAGE/CORE/MCO/
rm -rf MCO.tar
tar -cvf MCO.tar *
scp MCO.tar ${Writer_Server}:${Delivery_link}/INT/MCO
rm -rf MCO.tar


################ Tools (Genesis ) ################################################################

cd ${GENESIS_HOME}/GENESIS/$Version
rm -f Genesis.tar
tar -cvf Genesis.tar *
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Tools/Genesis ; mkdir -p ${Delivery_link}/INT/Tools/Genesis"
scp Genesis.tar ${Writer_Server}:${Delivery_link}/INT/Tools/Genesis
rm -rf Genesis.tar


############  Scripts ############################################################################
			
cd ${GENESIS_HOME}
rm -f Scripts.tar
tar -cvf Scripts.tar Scripts
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Tools/Scripts ; mkdir -p ${Delivery_link}/INT/Tools/Scripts"
scp Scripts.tar ${Writer_Server}:${Delivery_link}/INT/Tools/Scripts
rm -f Scripts.tar

			
######## CPG + UXFME	##########################################################################

ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Packages/CPG/v${Version}; mkdir -p ${Delivery_link}/INT/Packages/CPG/v${Version}"
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Packages/UXFME/v${Version}; mkdir -p ${Delivery_link}/INT/Packages/UXFME/v${Version}"
cd /XPISTORAGE/CORE/CPG/v${Version}
scp CPG.tar ${Writer_Server}:${Delivery_link}/INT/Packages/CPG/v${Version}
cd /XPISTORAGE/CORE/UXFME/v${Version}
scp UXFME.tar ${Writer_Server}:${Delivery_link}/INT/Packages/UXFME/v${Version}

			
########  ABP - Prep (start_maestro_sh , stop_maestro_sh , clean_maestro_sh )##################

cd /XPISTORAGE/CORE/ABP/64/TWS
rm -rf TWS.tar	
tar -cvf TWS.tar *
scp TWS.tar ${Writer_Server}:${Delivery_link}/INT/ABP
ssh $Writer_Server -n "cd ${Delivery_link}/INT/ABP; tar -xvf TWS.tar"
ssh $Writer_Server -n "rm -rf ${Delivery_link}/INT/ABP/TWS.tar "
rm -rf TWS.tar

########  CRM - Prep (CRM dmp) ###############################################################

cd /XPISTORAGE/${Version}/$CRM
CRM_STORAGE=`ls -trd ST_CRM* | tail -1`
cd $CRM_STORAGE
CRM_DMP_FILE=`ls -l | grep -v lrwx | grep dmp | awk '{print $9}'`
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/CRM ; mkdir -p ${Delivery_link}/INT/CRM"
scp ${CRM_DMP_FILE} ${Writer_Server}:${Delivery_link}/INT/CRM


########  AMF - Prep (Puppet Script) ##########################################################

cd /XPISTORAGE/CORE/AMF
AMF_PUPPET_FILE=`ls amf*`
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/AMF ; mkdir -p ${Delivery_link}/INT/AMF"
scp ${AMF_PUPPET_FILE} ${Writer_Server}:${Delivery_link}/INT/AMF

####### XPI  # amdocs-installer.tar ###########################################################

xpiNumber=`ssh ${Account}@${Server} -n "cd genesisTmpDir; cat line_cxpi.properties | grep cxpi.drop.number | grep PB | cut -d= -f2"`
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Packages/XPI ; mkdir -p ${Delivery_link}/INT/Packages/XPI"
cd /XPISTORAGE/CORE/XPI/64
rm -f xpi.tar
tar -cvf xpi.tar ${xpiNumber} 
scp xpi.tar ${Writer_Server}:${Delivery_link}/INT/Packages/XPI

##################  Boot Manager ############################################################## 

cd ${GENESIS_HOME}/PIL/custom/ExportDump
ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/Tools/BootManager"
scp PCI1_BootManager_configuration.xml ${Writer_Server}:${Delivery_link}/INT/Tools/BootManager


################# HOT-FIX  ( CUSTOM_DEPLOYMENTS ) #############################################

ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/Tools/HotFix"
cd ${GENESIS_HOME}/hotfix/CUSTOM_DEPLOYMENTS
tar cvf CUSTOM_DEPLOYMENTS.tar *
scp CUSTOM_DEPLOYMENTS.tar ${Writer_Server}:${Delivery_link}/INT/Tools/HotFix

exp $INF_TOOLS_DB_USER/$INF_TOOLS_DB_PASS@$INF_TOOLS_DB_INST file=CUSTOM_DEPLOYMENTS_METHODS.dmp log=CUSTOM_DEPLOYMENTS_METHODS.log tables=HOTFIX_DEPLOY_METHODS
scp CUSTOM_DEPLOYMENTS_METHODS.dmp ${Writer_Server}:${Delivery_link}/INT/Tools/HotFix


################# Ensight #############################################

ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/Tools/Ensight"
cd ${GENESIS_HOME}/ensight
ls *Api* > Ensight_APIs
ls *Config* > Ensight_Configs
rm -f Ensight_APIs.tar Ensight_Configs.tar
tar -cvf Ensight_APIs.tar -T Ensight_APIs
tar -cvf Ensight_Configs.tar -T Ensight_Configs
scp Ensight_APIs.tar ${Writer_Server}:${Delivery_link}/INT/Tools/Ensight
scp Ensight_Configs.tar ${Writer_Server}:${Delivery_link}/INT/Tools/Ensight
rm -f Ensight_APIs* 
rm -f Ensight_Configs*

