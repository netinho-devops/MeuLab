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
Delivery_link=$2
#Delivery link shoudl be with full path
Account=$3
Server=$4
Product=$5
Layer=$6
Reader_Server=bssdlv@illin1339
Writer_Server=bssdel@illin1339

###################### Initialization Area - End  ################################################


####################### variable #################################################################

if [ $# -ne 4 ]
then
     print "\n\tUSAGE : `basename $0` <Version> <Delivery_link> <Account> <Server>"
     exit 1
fi

##################################################################################################


###################### Create directories and link ###############################################



ssh $Writer_Server -n "rm ${Delivery_link}/INT ; mkdir -p ${Delivery_link}/INT"
link_name=`echo ${Delivery_link} |awk -F"\/" '{print $NF}'`
ssh $Reader_Server -n "cd /bssdlvhome/bss/dlv/bssdlv ;rm -f ${link_name}; ln -s ${Delivery_link} ."



############ MCO.tar ############################################################################

ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/MCO; mkdir -p ${Delivery_link}/INT/MCO"
cd /XPISTORAGE/CORE/MCO/
rm -rf MCO.tar
tar -cvf MCO.tar *
scp MCO.tar  $Writer_Server:${Delivery_link}/INT/MCO
rm -rf MCO.tar


################ Tools (Genesis ) ################################################################

cd /bssxpinas/bss/tooladm/GENESIS/$Version
tar -cvf Genesis.tar *
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Tools/Genesis ; mkdir -p ${Delivery_link}/INT/Tools/Genesis"
scp Genesis.tar $Writer_Server:${Delivery_link}/INT/Tools/Genesis
rm -rf Genesis.tar


############  Scripts ############################################################################
			
cd /bssxpinas/bss/tooladm/
tar -cvf Scripts.tar Scripts
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Tools/Scripts ; mkdir -p ${Delivery_link}/INT/Tools/Scripts"
scp Scripts.tar $Writer_Server:${Delivery_link}/INT/Tools/Scripts

			
######## CPG + UXFME	##########################################################################

ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Packages/CPG/v${Version}; mkdir -p ${Delivery_link}/INT/Packages/CPG/v${Version}"
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Packages/UXFME/v${Version}; mkdir -p ${Delivery_link}/INT/Packages/UXFME/v${Version}"
cd /XPISTORAGE/CORE/CPG/v${Version}
scp CPG.tar $Writer_Server:${Delivery_link}/INT/Packages/CPG/v${Version}
cd /XPISTORAGE/CORE/UXFME/v${Version}
scp UXFME.tar $Writer_Server:${Delivery_link}/INT/Packages/UXFME/v${Version}

			
########  APX and SDK.tar - Prep  ( config_apx.tar )##########################################################

cd /bssxpinas/bss/tooladm/config/$Version/APX/
rm -rf config_apx.tar
tar -cvf config_apx.tar *
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/APX; mkdir -p ${Delivery_link}/INT/APX"
scp config_apx.tar $Writer_Server:${Delivery_link}/INT/APX
rm -rf config_apx.tar
cd /XPISTORAGE/$Version/APX
rm -rf SDK.tar
tar -cvf SDK.tar SDK	
ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/APX"
scp SDK.tar $Writer_Server:${Delivery_link}/INT/APX
rm -rf SDK.tar

		
########  ABP - Prep (start_maestro_sh , stop_maestro_sh , clean_maestro_sh )##################

cd /XPISTORAGE/CORE/ABP/64/TWS
rm -rf TWS.tar	
tar -cvf TWS.tar *
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/ABP; mkdir -p ${Delivery_link}/INT/ABP"
scp TWS.tar $Writer_Server:${Delivery_link}/INT/ABP
ssh $Writer_Server -n "cd ${Delivery_link}/INT/ABP; tar -xvf TWS.tar"
ssh $Writer_Server -n "rm -rf ${Delivery_link}/INT/ABP/TWS.tar "
rm -rf TWS.tar

		
#######  CRM - Prep############################################################################
		
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/CRM; mkdir -p  ${Delivery_link}/INT/CRM"
cd /XPISTORAGE/CRM_Dumps/V$Version/Latest_SWP
tar -cvf CRM.tar *
scp CRM.tar  ${Writer_Server}:${Delivery_link}/INT/CRM
ssh $Writer_Server -n "cd ${Delivery_link}/INT/CRM ; tar -xvf CRM.tar ; rm -rf CRM.tar "
cd /XPISTORAGE/CRM_Dumps/V$Version/Latest_SWP
rm -rf CRM.tar

		
#########  ABP   Core Prep - ABP_core_packages.tar   ########################################

cd /XPISTORAGE/BUILD_RELEASE/ABP/v${Version}/64
BN_Number=`ls -l BN_CURRENT | awk -F/ '{print $NF}'`
cd /XPISTORAGE/BUILD_RELEASE/ABP/v$Version/64/$BN_Number
tarpath=`ls -l *.jar | grep lrwx | grep /XPISTORAGE/CORE/ABP | awk '{print $11}' | awk -F"\/" '{$NF=""}1' 2>/dev/null |sed -e "s/ /\//g" 2>/dev/null | sort -u | awk -F"/" '{print "/"$2"/"$3"/"$4"/"$5}'` 
tarname=`ls -l *.jar | grep lrwx | grep /XPISTORAGE/CORE/ABP | awk '{print $11}' | awk -F"\/" '{$NF=""}1' 2>/dev/null |sed -e "s/ /\//g" 2>/dev/null | sort -u | awk -F"/" '{print $6}'`
cd ${tarpath}
rm -rf ABP_core_packages.tar
tar cvf ABP_core_packages.tar ${tarname} 
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Packages/ABP; mkdir -p ${Delivery_link}/INT/Packages/ABP"
scp ABP_core_packages.tar $Writer_Server:${Delivery_link}/INT/Packages/ABP
rm -rf ABP_core_packages.tar


######## CRM/OMS/AMSS ### Core Prep ### ( CRM/OMS/AMSS_core_packages.tar ) #####################

for i in CRM OMS AMSS ; 
do
	cd /XPISTORAGE/BUILD_RELEASE/${i}/v${Version}/64OG
	BN_Number=`ls -l BN_CURRENT | awk -F/ '{print $NF}'`
	cd /XPISTORAGE/BUILD_RELEASE/${i}/v$Version/64OG/${BN_Number}
	tarpath=`ls -l *.jar | grep lrwx | grep /XPISTORAGE/CORE/${i} | awk '{print $11}' | awk -F"\/" '{$NF=""}1' 2>/dev/null |sed -e "s/ /\//g" 2>/dev/null | sort -u | awk -F"/" '{print "/"$2"/"$3"/"$4"/"$5}'` 
	tarname=`ls -l *.jar | grep lrwx | grep /XPISTORAGE/CORE/${i} | awk '{print $11}' | awk -F"\/" '{$NF=""}1' 2>/dev/null |sed -e "s/ /\//g" 2>/dev/null | sort -u | awk -F"/" '{print $6}'`
	cd ${tarpath}
	rm -rf ${i}_core_packages.tar
	tar cvf ${i}_core_packages.tar ${tarname} 
	ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Packages/${i}; mkdir -p ${Delivery_link}/INT/Packages/${i}"
	scp ${i}_core_packages.tar ${Writer_Server}:${Delivery_link}/INT/Packages/${i}
	rm -rf ${i}_core_packages.tar
done


########  ABP - Custom Prep ( ABP_custom_packages.tar ) ########################################
	
cd /XPISTORAGE/BUILD_RELEASE/ABP/v${Version}/64
BN_Number=`ls -l BN_CURRENT | awk -F/ '{print $NF}'`
export BN_Number
cd /XPISTORAGE/BUILD_RELEASE/ABP/v$Version/64/${BN_Number}
ls -l *.jar | grep -v lrwx | grep ABP | awk '{print ENVIRON["BN_Number"]"/" $9}' > tarname
ls -l *.jar | grep -v lrwx | grep TC | awk '{print ENVIRON["BN_Number"]"/" $9}' >> tarname
ls -l *build.number | awk '{print ENVIRON["BN_Number"]"/" $9}' >> tarname
cd /XPISTORAGE/BUILD_RELEASE/ABP/v$Version/64
rm -rf ABP_custom_packages.tar
tar cvf ABP_custom_packages.tar -T $BN_Number/tarname
rm -f $BN_Number/tarname
scp   ABP_custom_packages.tar $Writer_Server:${Delivery_link}/INT/Packages/ABP/
rm -rf ABP_custom_packages.tar
unset BN_Number

	
########  AMSS/CRM/OMS - Custom Prep ( CRM/OMS/AMSS_custom_packages.tar ) ######################

for i in CRM OMS AMSS ; 
do		
	cd /XPISTORAGE/BUILD_RELEASE/${i}/v${Version}/64OG
	BN_Number=`ls -l BN_CURRENT | awk -F/ '{print $NF}'`
	export BN_Number
	cd /XPISTORAGE/BUILD_RELEASE/${i}/v$Version/64OG/${BN_Number}
	ls -l *.jar | grep -v lrwx | grep ${i} | awk '{print ENVIRON["BN_Number"]"/" $9}' > $i_list.list
	ls -l *build.number | awk '{print ENVIRON["BN_Number"]"/" $9}' >> $i_list.list
        cd /XPISTORAGE/BUILD_RELEASE/${i}/v$Version/64OG
	rm -rf ${i}_custom_packages.tar
	tar cvf ${i}_custom_packages.tar -T $BN_Number/$i_list.list
	rm -f $BN_Number/$i_list.list
	scp ${i}_custom_packages.tar ${Writer_Server}:${Delivery_link}/INT/Packages/${i}
	rm -rf ${i}_custom_packages.tar
done


####### EPC - CORE Prep  ( EPC.tar ) ###########################################################

ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/Packages/EPC"
cd /XPISTORAGE/CORE/EPC/v${Version}
scp EPC.tar ${Writer_Server}:${Delivery_link}/INT/Packages/EPC


########## CXPI - CORE Prep ####################################################################

cd /XPISTORAGE/CORE/CXPI/64
rm -f CXPI_core_packages.tar
tar -cvf CXPI_core_packages.tar v950
ssh $Writer_Server -n "rm -fR ${Delivery_link}/INT/Packages/CXPI; mkdir -p ${Delivery_link}/INT/Packages/CXPI"
scp CXPI_core_packages.tar ${Writer_Server}:${Delivery_link}/INT/Packages/CXPI
rm -rf CXPI_core_packages.tar	


#######  CXPI - Custom Prep #####################################################################

ssh ${Account}@${Server} -n "cd storage_root/packages; rm -f CXPI_custom_packages.tar; tar cvf CXPI_custom_packages.tar Portfolio9*xdk.jar"
#link_place=`ls -l Portfolio3*.jar | awk '{print $11}' |awk -F"\/" '{print $1"\/"$2"\/"$3"\/"$4"\/"$5"\/"$6}'`
#cd $link_place
#ls Portfolio3*.jar > Portfolio.list
#ls Portfolio5*.jar >> Portfolio.list
cd /XPISTORAGE/BUILD_RELEASE/ABP/v${Version}/64
BN_Number=`ls -l BN_CURRENT | awk -F/ '{print $NF}'`
BNN=`echo $BN_Number | awk -F_ '{print $2}'`
cd /XPISTORAGE/${Version}/ABP/ST_ABP_V${Version}_B${BNN}/packages
scp -r  ${Account}@${Server}:storage_root/packages/CXPI_custom_packages.tar .
tar uvf CXPI_custom_packages.tar Portfolio5*.jar
tar uvf CXPI_custom_packages.tar Portfolio3*.jar
scp CXPI_custom_packages.tar ${Writer_Server}:${Delivery_link}/INT/Packages/CXPI
rm -rf CXPI_custom_packages.tar
ssh  ${Account}@${Server} -n "cd storage_root/packages ; rm -rf CXPI_custom_packages.tar"


####### XPI  # amdocs-installer.tar ###########################################################


xpiNumber=`ssh ${Account}@${Server} -n "cd genesisTmpDir; cat line_cxpi.properties | grep cxpi.drop.number | grep PB | cut -d= -f2"`
ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/Packages/XPI/${xpiNumber}"
cd /XPISTORAGE/CORE/XPI/64/${xpiNumber}
scp amdocs-installer.tar ${Writer_Server}:${Delivery_link}/INT/Packages/XPI/${xpiNumber}


#######  APX-last strorage  #######################################################################

cd /XPISTORAGE/${Version}/APX
tarname=`ls -l | grep ST_APX_V${Version}_B[0-9]*$ | awk -F_B '{print $NF}' | sort -n | tail -1 | awk '{print "ST_APX_V"'${Version}'"_B"$1}'`
tarbuild=`ls -l | grep ST_APX_V${Version}_B[0-9]*$ | awk -F_B '{print $NF}' | sort -n | tail -1`
tar cvf ST_APX_V${Version}_B${tarbuild}.tar ST_APX_V${Version}_B${tarbuild}
ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/Packages/APX"
scp ST_APX_V${Version}_B${tarbuild}.tar ${Writer_Server}:${Delivery_link}/INT/Packages/APX
rm -rf ST_APX_V${Version}_B${tarbuild}.tar
				

############link                   ############################################################			
			
for i in CRM OMS AMSS ; 
do		
	cd /XPISTORAGE/BUILD_RELEASE/${i}/v${Version}/64OG
	BN_Number=`ls -l BN_CURRENT | awk -F/ '{print $NF}'`
	cd /XPISTORAGE/BUILD_RELEASE/${i}/v${Version}/64OG/${BN_Number}
	ls -l | grep ^lrwx |  awk '{print $9}' > list 				
	tar -cvf ${i}_link.tar -T list
	scp ${i}_link.tar ${Writer_Server}:${Delivery_link}/INT/Packages/${i}
done
		
cd /XPISTORAGE/BUILD_RELEASE/ABP/v$Version/64
BN_Number=`ls -l BN_CURRENT | awk -F/ '{print $NF}'`
cd /XPISTORAGE/BUILD_RELEASE/ABP/v${Version}/64/${BN_Number}
ls -l | grep ^lrwx |  awk '{print $9}' > list
tar -cvf ABP_link.tar -T list
scp ABP_link.tar ${Writer_Server}:${Delivery_link}/INT/Packages/ABP


##################  Boot Manager ############################################################## 

cd /bssxpinas/bss/tooladm/PIL/custom/ExportDump
ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/Tools/BootManager"
scp PCI1_BootManager_configuration.xml ${Writer_Server}:${Delivery_link}/INT/Tools/BootManager


################# HOT-FIX  ( CUSTOM_DEPLOYMENTS ) #############################################

ssh $Writer_Server -n "mkdir -p ${Delivery_link}/INT/Tools/HotFix"
cd /bssxpinas/bss/tooladm/hotfix/CUSTOM_DEPLOYMENTS
tar cvf CUSTOM_DEPLOYMENTS.tar *
scp CUSTOM_DEPLOYMENTS.tar ${Writer_Server}:${Delivery_link}/INT/Tools/HotFix

exp tooladm/tooladm@BS9INF file=CUSTOM_DEPLOYMENTS_METHODS.dmp log=CUSTOM_DEPLOYMENTS_METHODS.log tables=HOTFIX_DEPLOY_METHODS
scp CUSTOM_DEPLOYMENTS_METHODS.dmp ${Writer_Server}:${Delivery_link}/INT/Tools/HotFix
