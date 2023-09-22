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
APRM_BN=$3
GENESIS_HOME=/bssxpinas/bss/tooladm
INF_TOOLS_DB_USER=tooladm
INF_TOOLS_DB_PASS=tooladm
INF_TOOLS_DB_INST=BS9INF
Reader_Server=bssdlv@illin1339
Writer_Server=bssdel@illin1339

###################### Initialization Area - End  ################################################


####################### variable #################################################################

if [ $# -ne 3 ]
then
     print "\n\tUSAGE : `basename $0` <Version> <Delivery_link> APRM_BN"
     exit 1
fi

##################################################################################################


###################### Create directories and link ###############################################

ssh $Writer_Server -n "rm ${Delivery_link}/INT ; mkdir -p ${Delivery_link}/INT"
link_name=`echo ${Delivery_link} |awk -F"\/" '{print $NF}'`
ssh $Reader_Server -n "cd /bssdlvhome/bss/dlv/bssdlv ;rm -f ${link_name}; ln -s ${Delivery_link} ."

for PRODUCT in PRM
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

	
##################################
#######################################
######################################
	echo $BN_PATH

##############

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
    
done
