#!/bin/ksh

##############################################################
## @ABOUT@ : Script for silent installation of omni on eaas ##
##############################################################

usage()
{
        echo "----------------------------------------------------------------------------------------------"
        echo
        echo "USAGE :"
        echo
        echo "`basename $0` -pkg <Package> [-clean]"
        echo
        echo "       -pkg : Complete path till the package"
        echo "     -clean : If given, Script will clean the account and then starts the installation"
        echo
        echo
        echo "----------------------------------------------------------------------------------------------"
        echo
}

if [ $# -eq 0 ]; then usage; exit 1 ; fi

while [[ $1 != '' ]]
do
        case $1 in
                -pkg)
                        export PACKAGE=$2
                        PACKAGE_PATH=`dirname $PACKAGE`
                        CXPI_PATH=`dirname $PACKAGE_PATH`/CXPI
                        shift
                        shift
                        ;;
              -clean)
                        export CLEAN_FLAG=1
                        shift
                        ;;
                   *)
                        usage
                        exit 1
                        ;;
        esac
done

###########################################################
## -------------- Checking Mandatory args--------------- ##
###########################################################

if [[ -z $PACKAGE ]]
then
        echo
        echo "Missing mandatory argument(s) !!!"
        echo
        usage
        exit 1
fi

###########################################################
## ------------------ Default variables ---------------- ##
###########################################################

TOPOLOGY="OmniChannel1_Basic.topology"
PROPFILE="${HOME}/OmniChannel1_Basic.properties"

###########################################################
## ------------- Clean the env if user wants ----------- ##
###########################################################

cleanEnv()
{
        if [ -n "$CLEAN_FLAG" ]
        then
                echo
                echo "Cleaning the environment.."
                echo
        
                rm -rf ~/* ~/.??*
        
                if [ `ps -fu ${USER} | grep -i java | grep -v grep | wc -l` -gt 0 ]
                then
                        for PID in `ps -fu ${USER} | grep -i java | grep -v grep | awk '{print $2}'`
                        do
                                kill -9 $PID
                        done
                fi
        fi
}

###########################################################
## ----------------Copy the installer ------------------ ##
###########################################################

copyInstaller()
{
	if [ ! -f "$PACKAGE_PATH/amdocs-installer.tar" ]
	then
		echo "Installer is not present at $PACKAGE_PATH !!"
		echo
		echo "Copying the installer from $CXPI_PATH "
		echo

		if [ -f "$CXPI_PATH/amdocs-installer.tar" ]
		then
			cp "$CXPI_PATH/amdocs-installer.tar" $HOME
		else
			echo
			echo "Installer is not present at $CXPI_PATH !!"
			echo "Kindly copy the installer to $PACKAGE_PATH to proceed with the installation"
			echo
			exit 1
		fi
	else
		echo "Copying amdocs-installer.tar.."
		cp "$PACKAGE_PATH/amdocs-installer.tar" $HOME
	fi

	echo
	echo "Extracting the installer.."
	echo
	tar -xf "$HOME/amdocs-installer.tar"
}


###########################################################
## ------------------- Installation -------------------- ##
###########################################################

launchInstaller()
{
	~/installer/bin/xpi_installer.sh --mem huge --silent --install -p "$PACKAGE" -t "$TOPOLOGY" -pr "$PROPFILE" 
	# 1>~/OMNIInstaller.log	
	export INSTALL_STATUS=$?
}


###########################################################
## ----------- Check the Installation status ----------- ##
###########################################################

checkStatus()
{
	if [ $INSTALL_STATUS -ne 0 ]
	then
		echo
		echo "INSTALLATION IS UNSUCCESSFUL !! Please check the logs for errors"
		echo
		exit 1
	else
		echo
		echo "####################################"
		echo "#  INSTALLATION IS SUCCESSFUL !!   #"
		echo "####################################"
		echo
	fi	
	
}


###########################################################
## -------------- Create the profile file -------------- ##
###########################################################

createProfile()
{
	echo "#!/bin/ksh"
	echo "set -o emacs"
	echo "MYHOST=`hostname`"
	echo "MYHOME=`dirname ${HOME}`"
	echo "export PS1='${USER}@${MYHOST}:~${PWD##${MYHOME}/}> '"
	echo "export PATH=${JAVA_HOME}/bin:${ORACLE_HOME}/bin:${PATH}"
	echo "alias ll='/bin/ls -Alrt'"
	echo "alias psu='/bin/ps -fu ${USER}'"
        echo "alias omnis='cd $HOME/JEE/LightSaberDomain/scripts/LightSaberDomain/omni_LSJEE'"
        echo "alias omnir='omnis; ./startomni_LSJEE.sh'"
        echo "alias omnil='cd $HOME/JEE/LightSaberDomain/logs/LightSaberDomain/omni_LSJEE'"
        echo "alias omnit='omnil; tail -f `ls -tr weblogic.*| tail -1`'"
        echo "alias omniv='omnil; less `ls -tr weblogic.*| tail -1`'"
        echo "export ORACLE_HOME=/oravl01/oracle/12.1.0.2"
        echo "export JAVA_HOME=/usr/java/jdk1.8.0_31"
        echo "export OMNI_APP_HOST=eaasrt"
        echo "export OMNI_APP_USER=pciomi1"
}


###########################################################
## ----------------- Create property file -------------- ##
###########################################################

createPropertyFile()
{
	echo "OmniChannel-account-1/password=Unix11!"
        echo "OmniChannel-account-1/name=${USER}"
        echo "OmniChannel-machine-1/parallel.degree="
        echo "OmniChannel-machine-1/unmanaged=false"
        echo "OmniChannel-machine-1/name=${HOST}"
	echo "OmniChannel/OmniChannel1.global.is.exploded.ears=true"
        echo "OmniChannel/xpi.security.asm.home="
        echo "OmniChannel/xpi.security.asm.template="
        echo "OmniChannel/omniChannel1.global.is.arim=if(xpi-cond('(EXIST(ARIM))'),'true','false')"
        echo "OmniLightSaberServer/ls1.global.config.dir=${HOME}/config/LS/ASC"
        echo "OmniLightSaberServer/ls1.global.asc.root.name=CM1_root.conf"
        echo "OmniLightSaberServer/ls1.global.asc.lightsaber.node.path=/UXFCore"
        echo "OmniLightSaberServer/ls1.global.asm.dir=${HOME}/config/LS/ASM"
        echo "OmniLightSaberServer/ls1.global.uams.dbHost=${UAMS_DB_HOST}"
        echo "OmniLightSaberServer/ls1.global.uams.dbPort=1521"
        echo "OmniLightSaberServer/ls1.global.uams.dbUser=${UAMS_DB_USER}"
        echo "OmniLightSaberServer/ls1.global.uams.dbPass=<UEM>K=<key>.asc.sys.encryption.0;C=1432647324796;M=CAf{pZxbpMT}Ygzn}7u5E12;</UEM>"
        echo "OmniLightSaberServer/ls1.global.uams.dbInst=${UAMS_DB_INST}"
        echo "OmniLightSaberServer/ls1.global.uams.dbTNS=/etc"
        echo "OmniLightSaberServer/ls1.global.session.uams.dbHost=${UAMS_DB_HOST}"
        echo "OmniLightSaberServer/ls1.global.session.uams.dbPort=1521"
        echo "OmniLightSaberServer/ls1.global.session.uams.dbUser=${UAMS_DB_USER}"
        echo "OmniLightSaberServer/ls1.global.session.uams.dbPass=<UEM>K=<key>.asc.sys.encryption.0;C=1432647324798;M=CAf{pZxbpMT}Ygzn}7u5E12;</UEM>"
        echo "OmniLightSaberServer/ls1.global.session.uams.dbInst=${UAMS_DB_INST}"
        echo "OmniLightSaberServer/ls1.container.server.type=WLS"
        echo "OmniLightSaberServer/ls1.global.base.port=43830"
        echo "OmniLightSaberServer/ls1.container.vendor.home=if(xpi-cond('(($(ls1.container.server.type))==(WLS))')='true','/opt/weblogic1213/wlserver_12.1.3/installation/wlserver','$(ls1.env.was.home)')"
        echo "OmniChannel/OmniLightSaberServer/ls1.java.home.global=/usr/java/jdk1.8.0_31/"
        echo "OmniLightSaberServer/OmniChannel1.config.is.abp=true"
        echo "OmniLightSaberServer/OmniChannel1.config.is.crm=true"
        echo "OmniLightSaberServer/OmniChannel1.config.is.oms=true"
        echo "OmniLightSaberServer/OmniChannel1.config.is.mcss=if($is.Portfolio.mode,if($cp1.amss.exist="true","true","false"),"false")"
        echo "OmniLightSaberServer/OmniChannel1.config.is.se=true
        echo "OmniLightSaberServer/OmniChannel1.config.is.ebill=if($is.Portfolio.mode,if($cp1.amss.exist="true","true","false"),"false")"
        echo "OmniLightSaberServer/OmniChannel1.config.is.webuser=if($is.Portfolio.mode,if($cp1.amss.exist="true","true","false"),"false")"
        echo "OmniLightSaberServer/OmniChannel1.config.is.insight=if($is.Portfolio.mode,if($cp1.insight.exist="true","true","false"),"false")"
        echo "OmniLightSaberServer/OmniChannel1.config.is.fts=xpi-cond('(EXIST(OUTGOING_RELATION(omniChannel1.conf.fts.jee.relation)))')"
        echo "OmniLightSaberServer/OmniChannel1.conf.abp.provider.url=${HOST}:42361"
        echo "OmniLightSaberServer/OmniChannel1.conf.crm.provider.url=${HOST}:43403"
        echo "OmniLightSaberServer/OmniChannel1.conf.oms.provider.url=${HOST}:43500"
        echo "OmniLightSaberServer/OmniChannel1.conf.mcss.provider.url="
        echo "OmniLightSaberServer/OmniChannel1.conf.se.provider.url=${HOST}:43500"
        echo "OmniLightSaberServer/OmniChannel1.conf.ebill.provider.url="
        echo "OmniLightSaberServer/OmniChannel1.conf.webuser.provider.url="
        echo "OmniLightSaberServer/OmniChannel1.conf.fts.provider.url="
        echo "OmniLightSaberServer/OmniChannel1.conf.insight.provider.url="
        echo "OmniLightSaberServer/OmniChannel1.conf.insight.proxy.username=insightClient"
        echo "OmniLightSaberServer/OmniChannel1.conf.insight.proxy.password="
	echo "omni_Storage/storage.path.param/xpi.StoragePath=$(user.home)"
        echo "omni_Storage/storage.path.param/xpi.StoragePhysicalPath="
        echo "omni_Storage/storage.path.param/xpi.CreateDirectoryIfNeeded=true"
        echo "omni_Storage/storage.path.param/xpi.skipStoragePostInstallationValidation=true"
        echo "omni_LSJEE/container.is.listen.port.enabled=true"
        echo "omni_LSJEE/container.listen.port=string($ls1.global.base.port+0)"
        echo "omni_LSJEE/container.is.ssl.listen.port.enabled=true"
        echo "omni_LSJEE/container.ssl.listen.port=string($container.listen.port+1)"
        echo "omni_LSJEE/ls1.container.is.debug.port.enabled=false"
        echo "omni_LSJEE/ls1.container.jmx/ls1.container.jmx.enabled=false"
        echo "omni_LSJEE/ls1.container.jmx/ls1.container.jmx.port=0000"
        echo "omni_LSJEE/ls1.container.jmx/ls1.container.jmx.authenticate=false"
        echo "omni_LSJEE/ls1.container.jmx/ls1.container.jmx.password.file=$(storage:xpi.StoragePath)/storage/LS/core/utilities/management/jmxremote.password"
        echo "omni_LSJEE/ls1.container.jmx/ls1.container.jmx.access.file=$(storage:xpi.StoragePath)/storage/LS/core/utilities/management/jmxremote.access"
        echo "omni_LSJEE/ls1.container.jvm.nonproxy.hosts=illin*|indlin*|ilmtx*|indmtx*"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.aif.database.details/ls1.aif.database.user="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.aif.database.details/ls1.aif.database.password="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.aif.database.details/ls1.aif.database.url="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.uams.properties/ls1.uams.properties.oms.conn.loginsp.disabled=0"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.uams.properties/ls1.uams.properties.oms.sec.srv.conn=hpx626:20500"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.uams.properties/ls1.uams.properties.ignore.multiple.login=false"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.caching.remote.cache.enabled=false"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.caching.remote.cache.name="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.caching.remote.cache.default.time.to.live="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.caching.remote.cache.monitoring.scheduler.time.interval=600000"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines1/ls1.caching.remote.cache.machine1="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines1/ls1.caching.remote.cache.port1="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines1/ls1.caching.remote.cache.machine2="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines1/ls1.caching.remote.cache.port2="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines1/ls1.caching.remote.cache.machine3="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines1/ls1.caching.remote.cache.port3="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines2/ls1.caching.remote.cache.machine4"=
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines2/ls1.caching.remote.cache.port4="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines2/ls1.caching.remote.cache.machine5="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines2/ls1.caching.remote.cache.port5="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines2/ls1.caching.remote.cache.machine6="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.remote.cache/ls1.remote.cache.machines2/ls1.caching.remote.cache.port6="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.messagesDefinition/ls1.asc.message.resource=Files"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.messagesDefinition/ls1.asc.message.refreshInt=1800"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.messageDefinition.DB/ls1.messageDefinition.DB.type=regular"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.messageDefinition.DB/ls1.messageDefinition.DB.user=onpdev62"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.messageDefinition.DB/ls1.messageDefinition.DB.password=<UEM>K=<key>.asc.sys.encryption.0;C=1339335722184;M=dD9FDh61ZdR{ws7w4lknW02;</UEM>"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.messageDefinition.DB/ls1.messageDefinition.DB.instance=oms1d80"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.messageDefinition.DB/ls1.messageDefinition.DB.host=linva20"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.messageDefinition.DB/ls1.messageDefinition.DB.port=1521"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.messageDefinition.DB/ls1.resource.bundle.utility.exec=Yes"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.security.csrf.enabled=false"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.keyManagement.keystorepath=if('$(jee:container.server.type)'='WAS','$(storage:xpi.StoragePath)/storage/LS/core/utilities/keyStores/WAS/lskeystore.jck','$(storage:xpi.StoragePath)/storage/LS/core/utilities/keyStores/lskeystore.jck')"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.keyManagement.keystorepassword=<UEM>K=<key>.asc.sys.encryption.0;C=1395221157391;M=iTtyIbf3}YlZlU1fKWtO}M{sOePyZTzc0;</UEM>"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.key.management.session.token.keys/ls1.key.management.active.session.token.alias=currentencryptionkey"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.key.management.session.token.keys/ls1.key.management.active.session.token.password=<UEM>K=<key>.asc.sys.encryption.0;C=1339335943893;M=gRDFp}gob7PRPQTPBVkpo2sCXLKTF9UL9Adu3H}i5pb4;</UEM>"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.key.management.session.token.keys/ls1.key.management.previous.session.token.alias=previousencryptionkey"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.key.management.session.token.keys/ls1.key.management.previous.session.token.password=<UEM>K=<key>.asc.sys.encryption.0;C=1339335948875;M=K{K5hzSG2Cpj6awVrPiONCXueqrtrvPf{uk9QrYmCI24;</UEM>"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.key.management.csrf.token.keys/ls1.key.management.active.csrf.token.alias=csrfcurrentencryptionkey"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.key.management.csrf.token.keys/ls1.key.management.active.csrf.token.password=<UEM>K=<key>.asc.sys.encryption.0;C=1348060964537;M=wpdiylXyHuPwqt3WFliIxLncuMzGv4eo0;</UEM>"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.key.management.csrf.token.keys/ls1.key.management.previous.csrf.token.alias=csrfpreviousencryptionkey"
        echo "omni_ls.configuration/ls1.installation.parameters/KeyManagement/ls1.key.management.csrf.token.keys/ls1.key.management.previous.csrf.token.password=<UEM>K=<key>.asc.sys.encryption.0;C=1348060979394;M=jjxi28hsiuXCYU9}hikLiX7xM18GiQSi0;</UEM>"
        echo "omni_ls.configuration/ls1.installation.parameters/post.sql.runner.group/ls1.messages.table.cre/db.connection.group/sql.runner.oracle.home=$ORACLE_HOME"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.resource.bundle.utility.exec.mode=File"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.refresh.time.interval=600000"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.dox.config.properties/ls1.docx.config.DB.type=regular"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.dox.config.properties/ls1.dox.user="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.dox.config.properties/ls1.dox.password="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.dox.config.properties/ls1.dox.instance="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.dox.config.properties/ls1.dox.server="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.dox.config.properties/ls1.dox.port=1521"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.dox.config.properties/ls1.dox.config.instance.id="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.dox.config.properties/ls1.dox.config.environment.id="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.dox.config.properties/ls1.dox.config.component.id="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.dox.config.properties/ls1.dox.config.name="
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.external.auth/ls1.externalAuth.mode=false"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.external.auth/ls1.externalAuth.header.user=SM_USER"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.external.auth/ls1.externalAuth.header.roles=SM_ROLES"
        echo "omni_ls.configuration/ls1.installation.parameters/ls1.external.auth/ls1.externalAuth.roles.delimiter=,"
        echo "omni_ls.configuration/ls1.installation.parameters/OmniChannel1.config.integrations/omnichannel1.insight.details/OmniChannel1.conf.insight.provider.url=$(omniChannel1.conf.insight.jee.relation:container.concated.url)"
        echo "omni_ls.configuration/ls1.installation.parameters/OmniChannel1.config.integrations/omnichannel1.insight.details/OmniChannel1.conf.insight.proxy.username="
        echo "omni_ls.configuration/ls1.installation.parameters/OmniChannel1.config.integrations/omnichannel1.insight.details/OmniChannel1.conf.insight.proxy.password="
        echo "omni_ls.configuration/ls1.installation.parameters/arim1.arim/arim1.asc.Ejb.IOmsServices.JndiHome="
        echo "omni_ls.configuration/ls1.installation.parameters/arim1.arim/arim1.asc.Ejb.IOmsServices.Connection="
        echo "omni_ls.configuration/ls1.installation.parameters/arim1.arim/arim1.asc.login.webservice.ServiceUrl=http://retaildev01v:8082/WSLogin.asmx"
        echo "omni_ls.configuration/ls1.installation.parameters/arim1.arim/arim1.asc.PaymentSecureUrl=http://retaildev01v:8082/CardProcess.aspx"
        echo "omni_ls.configuration/ls1.installation.parameters/arim1.arim/arim1.asc.pos.webservice.ServiceUrl=http://retaildev01v:8082/POSWebService.asmx"
        echo "omni_ls.configuration/ls1.installation.parameters/arim1.arim/arim1.asc.pos1.webservice.ServiceUrl=http://retaildev01v:8082/micropos1.asmx"
        echo "omni_ls.configuration/ls1.installation.parameters/arim1.arim/arim1.asc.ViewPrintReceiptUrl=http://retaildev01v:8082/TransView.aspx"
        echo "omni_SecurityRepository/xpi.FileSystemParameters/xpi.SecurityRepositoryPath="

}

###########################################################
## -------------- Server start-up script --------------- ##
###########################################################

startServer()
{
	echo
	echo "Starting the server.."
	echo
	cd $HOME/JEE/LightSaberDomain/scripts/LightSaberDomain/omni_LSJEE
	./startomni_LSJEE.sh
}


###########################################################
## -------------- Check the server status -------------- ##
###########################################################

checkServerStatus()
{
	FLAG=0
	COUNT=0
 	while [ $FLAG -eq 0 -a $COUNT -le 10 ]
	do
		HOSTNAME=`hostname`	
		WEBLOGIC_LOG=`ls -rt ${HOME}/JEE/LightSaberDomain/logs/LightSaberDomain/omni_LSJEE/weblogic*.log | tail -1`
		if [ `grep -wc RUNNING ${WEBLOGIC_LOG}` -gt 0 ]
		then
			FLAG=1
			echo ""
			echo "Server is Up and Running."
			echo
			echo "#############################################################################"
			echo
			echo
			exit 0
		fi
		
		sleep 15
		COUNT=`expr $COUNT + 1`
	done
	if [ $FLAG -eq 0 ]
	then
		echo
		echo "Server is not up. Please check start-up log."
		echo
	fi
}


###########################################################
## -------------- Post installation steps -------------- ##
###########################################################

postInstallSteps()
{
	cd ~
	createProfile > .profile
	. ./.profile
	startServer
	sleep 2
	echo "Checking the server status ..."
	checkServerStatus
}


###########################################################
## ------------------- Main section -------------------- ##
###########################################################

cleanEnv
copyInstaller
createPropertyFile > $PROPFILE
cd ~ 
echo "Installation is in process.."
launchInstaller
checkStatus

postInstallSteps
