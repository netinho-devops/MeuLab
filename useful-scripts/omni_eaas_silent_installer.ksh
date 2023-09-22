#!/bin/ksh

#--------------------------------------------------------------------
##=Name omni_eaas_silent_installer.ksh
##
##=Purpose - Script for silent installation of omni on eaas
##
##=Parameters - none
##
##=Author - Devendra Hupri
##
##=Date 02-Dec-2015
##
##=Updates and Fixes History
## --- Owner --- | --- Date --- | ------- Description ---------------
##               |              |
##               |              |
#--------------------------------------------------------------------


# -------------------------------------------------------------------
# --       F U N C T I O N   D E F I N I T I O N                   --
# -------------------------------------------------------------------

usage()
{
	echo "----------------------------------------------------------------------------------------------"
	echo
	echo "USAGE: `basename $0` -version <VERSION> [-package <Path_to_package>]"
	echo
	echo "-version : Product version: 2500,2600 etc"
	echo "-package : An optional argument. Takes default if not passed."
	echo " 		 Example : /XPISTORAGE/BUILD_RELEASE/OMNI/v2600/64OG/BN_8"
	echo "		 Default : /XPISTORAGE/BUILD_RELEASE/OMNI/v${VERSION}/64OG/BN_CURRENT"
	echo
	echo "----------------------------------------------------------------------------------------------"
}

export SCRIPT_PARAMS="$*"

if [ $# -eq 0 ]; then usage; exit 1 ; fi

# -------------------------------------------------------------------
# --       F U N C T I O N   D E F I N I T I O N                   --
# -------------------------------------------------------------------

Init()
{
	pack_flag=0	
	while [[ $1 != '' ]]
	do
	        case $1 in
	            -version)
	                        export VERSION=$2
				echo "VERSION : $VERSION"
				echo
	                        shift
	                        shift
	                        ;;
	            -package)
	                        pack_flag=1
				export PACKAGE_DIR=$2
	                        shift
	                        shift
	                        ;;
	    		   *)
	                        usage
	                        exit 1
	                        ;;
	        esac
	done
	
	if [ $PACKAGE_DIR == "LATEST" ]
	then
		export PACKAGE_DIR=`readlink -f /XPISTORAGE/BUILD_RELEASE/OMNI/v"${VERSION}"/64OG/BN_CURRENT`
		echo "PACKAGE PATH : $PACKAGE_DIR"
	else
		if [ ! -d "$PACKAGE_DIR" ]
		then
			echo "$PACKAGE_DIR not valid"
		else
			echo "Package : $PACKAGE_DIR"
		fi
	fi
	
	echo
	
	export AMDOCS_INSTALLER="$PACKAGE_DIR/installer"
	export PACKAGE=`ls $PACKAGE_DIR/OmniChannel9*full*.jar`
	export JAVA_HOME="/usr/java/jdk1.8.0_31"
	export ORACLE_HOME="/oravl01/oracle/12.1.0.2"
	export WL_HOME="/opt/weblogic1213/wlserver_12.1.3/installation/wlserver"
	export TOPOLOGY="OmniChannel9_Basic.topology"
	export BASE_PROPFILE="/mpsnas/scripts/OMNI_Scripts/PROPERTIES/Eaas_OmniChannel9_Basic.properties"
	export ANT_HOME="/usr/share/ant"
	cp $BASE_PROPFILE $HOME

}

# -------------------------------------------------------------------
# --       F U N C T I O N   D E F I N I T I O N                   --
# -------------------------------------------------------------------
# 	   	   Fetch free listen port 
# -------------------------------------------------------------------

getFreePort()
{
        QUIT=0
        OMNIPORT=50000
        
        echo "Fetching the available listen port.."
        sleep 1
        while [ "$QUIT" -eq 0 ]
        do
                netstat -an | grep -q  $OMNIPORT
                if [ $? -eq 0 ]
                then
                        OMNIPORT=`expr $OMNIPORT + 1000`
                else
                        QUIT=1
                fi
        done
        echo
}

# -------------------------------------------------------------------
# --       F U N C T I O N   D E F I N I T I O N                   --
# -------------------------------------------------------------------

copyInstaller()
{
	if [ ! -d "$AMDOCS_INSTALLER" ]
	then
		echo "Installer is not present $AMDOCS_INSTALLER !!"
		echo
		exit 1
	else
		echo "Copying amdocs-installer.tar.."
		cp -r "$AMDOCS_INSTALLER" $HOME
		rm -fr $HOME/installer/work/*
	fi

}


# -------------------------------------------------------------------
# --       F U N C T I O N   D E F I N I T I O N                   --
# -------------------------------------------------------------------

updatePropertyFile()
{
	HOME_PROPFILE="$HOME/Eaas_OmniChannel9_Basic.properties"
        UNIX_HOST=`hostname`
        UNIX_ACCOUNT=`whoami`


	ABP_UNIX_ACCOUNT=`echo ${USER} | cut -c 1-3`wrk`echo ${USER} | cut -c 7-20`
	CRM_UNIX_ACCOUNT=`echo ${USER} | cut -c 1-3`crm`echo ${USER} | cut -c 7-20`
	OMS_UNIX_ACCOUNT=`echo ${USER} | cut -c 1-3`oms`echo ${USER} | cut -c 7-20`
	AMS_UNIX_ACCOUNT=`echo ${USER} | cut -c 1-3`ams`echo ${USER} | cut -c 7-20`

	/mpsnas/MPS/EAAS/scripts/create_sshlogin.ksh -u ${ABP_UNIX_ACCOUNT} -h ${UNIX_HOST} -p Unix11!
	/mpsnas/MPS/EAAS/scripts/create_sshlogin.ksh -u ${CRM_UNIX_ACCOUNT} -h ${UNIX_HOST} -p Unix11!
	/mpsnas/MPS/EAAS/scripts/create_sshlogin.ksh -u ${OMS_UNIX_ACCOUNT} -h ${UNIX_HOST} -p Unix11!
	/mpsnas/MPS/EAAS/scripts/create_sshlogin.ksh -u ${AMS_UNIX_ACCOUNT} -h ${UNIX_HOST} -p Unix11!


	ABP_UNIX_PORT=`ssh ${ABP_UNIX_ACCOUNT}@${UNIX_HOST} "find ~/JEE -iname "setenv*ABP*.sh" | uniq | xargs grep LISTEN_PORT= | grep -v SSL | grep -v ^# | uniq" | awk -F "PORT=" '{print $2}' | tr -d '"' | tr -d ' '`
	OMS_UNIX_PORT=`ssh ${OMS_UNIX_ACCOUNT}@${UNIX_HOST} "find ~/JEE -iname "setenv*OMS*.sh" | grep -i omsserver | uniq | xargs grep LISTEN_PORT= | grep -v SSL | grep -v ^# | uniq" |awk -F "PORT=" '{print $2}' | tr -d '"' | tr -d ' '`
	CRM_UNIX_PORT=`ssh ${CRM_UNIX_ACCOUNT}@${UNIX_HOST} "find ~/JEE -iname "setenv*CRM*.sh" | grep -i crmserver | uniq | xargs grep LISTEN_PORT= | grep -v SSL | grep -v ^# | uniq" |awk -F "PORT=" '{print $2}' | tr -d '"' | tr -d ' '`
	AMS_UNIX_PORT=`ssh ${AMS_UNIX_ACCOUNT}@${UNIX_HOST} "find ~/JEE -iname "setenv*AMS*.sh" | grep -i AMSSFullServer | uniq | xargs grep LISTEN_PORT= | grep -v SSL | grep -v ^# | uniq" |awk -F "PORT=" '{print $2}' | tr -d '"' | tr -d ' '`

     
	UAMS_DB_USER=`ssh ${OMS_UNIX_ACCOUNT}@${UNIX_HOST} 'grep SEC_DB_USER \`find JEE -iname uams.properties\`' | awk -F "=" '{print $2}'`
	UAMS_DB_INSTANCE=`ssh ${OMS_UNIX_ACCOUNT}@${UNIX_HOST} 'grep SEC_DB_INST \`find JEE -iname uams.properties\`' | awk -F "=" '{print $2}'`
	UAMS_DB_HOST=`ssh ${OMS_UNIX_ACCOUNT}@${UNIX_HOST} 'grep SEC_DB_HOST  \`find JEE -iname uams.properties\`' | awk -F "=" '{print $2}'`
	UAMS_DB_PORT=`ssh ${OMS_UNIX_ACCOUNT}@${UNIX_HOST} 'grep SEC_DB_PORT \`find JEE -iname uams.properties\`' | awk -F "=" '{print $2}'`
	
	sed -i "s#OmniChannel-account-1/name=.*#OmniChannel-account-1/name=${UNIX_ACCOUNT}#g" ${HOME_PROPFILE}
	sed -i "s#OmniChannel-machine-1/name=.*#OmniChannel-machine-1/name=${UNIX_HOST}#g" ${HOME_PROPFILE}

	sed -i "s#OmniLightSaberServer/OmniChannel1.conf.abp.provider.url=.*#OmniLightSaberServer/OmniChannel1.conf.abp.provider.url=${UNIX_HOST}:${ABP_UNIX_PORT}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/OmniChannel1.conf.crm.provider.url=.*#OmniLightSaberServer/OmniChannel1.conf.crm.provider.url=${UNIX_HOST}:${CRM_UNIX_PORT}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/OmniChannel1.conf.oms.provider.url=.*#OmniLightSaberServer/OmniChannel1.conf.oms.provider.url=${UNIX_HOST}:${OMS_UNIX_PORT}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/OmniChannel1.conf.mcss.provider.url=.*#OmniLightSaberServer/OmniChannel1.conf.mcss.provider.url=${UNIX_HOST}:${AMS_UNIX_PORT}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/OmniChannel1.conf.se.provider.url=.*#OmniLightSaberServer/OmniChannel1.conf.se.provider.url=${UNIX_HOST}:${OMS_UNIX_PORT}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/OmniChannel1.conf.ebill.provider.url=.*#OmniLightSaberServer/OmniChannel1.conf.ebill.provider.url=${UNIX_HOST}:${AMS_UNIX_PORT}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.session.uams.dbHost=.*#OmniLightSaberServer/ls1.global.session.uams.dbHost=${UAMS_DB_HOST}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.session.uams.dbPort=.*#OmniLightSaberServer/ls1.global.session.uams.dbPort=${UAMS_DB_PORT}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.session.uams.dbUser=.*#OmniLightSaberServer/ls1.global.session.uams.dbUser=${UAMS_DB_USER}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.session.uams.dbPass=.*#OmniLightSaberServer/ls1.global.session.uams.dbPass=${UAMS_DB_USER}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.session.uams.dbInst=.*#OmniLightSaberServer/ls1.global.session.uams.dbInst=${UAMS_DB_INSTANCE}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.base.port=.*#OmniLightSaberServer/ls1.global.base.port=${OMNIPORT}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.uams.dbHost=.*#OmniLightSaberServer/ls1.global.uams.dbHost=${UAMS_DB_HOST}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.uams.dbPort=.*#OmniLightSaberServer/ls1.global.uams.dbPort=${UAMS_DB_PORT}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.uams.dbUser=.*#OmniLightSaberServer/ls1.global.uams.dbUser=${UAMS_DB_USER}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.uams.dbPass=.*#OmniLightSaberServer/ls1.global.uams.dbPass=${UAMS_DB_USER}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.global.uams.dbInst=.*#OmniLightSaberServer/ls1.global.uams.dbInst=${UAMS_DB_INSTANCE}#g" ${HOME_PROPFILE}
	sed -i "s#OmniChannel/OmniLightSaberServer/ls1.java.home.global=.*#OmniChannel/OmniLightSaberServer/ls1.java.home.global=${JAVA_HOME}#g" ${HOME_PROPFILE}
	sed -i "s#OmniLightSaberServer/ls1.container.vendor.home=.*#OmniLightSaberServer/ls1.container.vendor.home=${WL_HOME}#g" ${HOME_PROPFILE}
	sed -i "s#omni_ls.configuration/ls1.installation.parameters/post.sql.runner.group/ls1.messages.table.cre/db.connection.group/sql.runner.oracle.home=.*#omni_ls.configuration/ls1.installation.parameters/post.sql.runner.group/ls1.messages.table.cre/db.connection.group/sql.runner.oracle.home=${ORACLE_HOME}#g" ${HOME_PROPFILE}
}

# -------------------------------------------------------------------
# --       F U N C T I O N   D E F I N I T I O N                   --
# -------------------------------------------------------------------

launchInstaller()
{
	~/installer/bin/xpi_installer.sh --mem huge --silent --install -p "$PACKAGE" -t "$TOPOLOGY" -pr "$HOME_PROPFILE" 
	export INSTALL_STATUS=$?
}


# -------------------------------------------------------------------
# --       F U N C T I O N   D E F I N I T I O N                   --
# -------------------------------------------------------------------

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


# -------------------------------------------------------------------
# --       F U N C T I O N   D E F I N I T I O N                   --
# -------------------------------------------------------------------

createProfile()
{
	echo "#!/bin/ksh"
	echo "set -o emacs"
	echo "MYHOST=\`hostname\`"
	echo "MYHOME=\`dirname \${HOME}\`"
	echo "export PS1='\${USER}@\${MYHOST}:~\${PWD##\${MYHOME}/}> '"
	echo "export PATH=\${JAVA_HOME}/bin:\${ORACLE_HOME}/bin:\${PATH}"
	echo "alias ll='/bin/ls -Alrt'"
	echo "alias psu='/bin/ps -fu \${USER}'"
        echo "alias omnis='cd \$HOME/JEE/LightSaberDomain/scripts/LightSaberDomain/omni_LSJEE'"
        echo "alias omnir='omnis; ./startomni_LSJEE.sh'"
        echo "alias omnil='cd \$HOME/JEE/LightSaberDomain/logs/LightSaberDomain/omni_LSJEE'"
        echo "alias omnit='cd \$HOME/JEE/LightSaberDomain/logs/LightSaberDomain/omni_LSJEE; tail -f \`ls -tr weblogic.*| tail -1\`'"
        echo "alias omniv='cd \$HOME/JEE/LightSaberDomain/logs/LightSaberDomain/omni_LSJEE; less \`ls -tr weblogic.*| tail -1\`'"
        echo "export ORACLE_HOME=/oravl01/oracle/12.1.0.2"
        echo "export JAVA_HOME=/usr/java/jdk1.8.0_31"
        echo "export OMNI_APP_HOST=\`hostname\`"
        echo "export OMNI_APP_USER=\$USER"
}


# -------------------------------------------------------------------
# --       F U N C T I O N   D E F I N I T I O N                   --
# -------------------------------------------------------------------

postInstallSteps()
{
	cd ~
	createProfile > .profile
	. ~/.profile
}


###########################################################
## ------------------- Main section -------------------- ##
###########################################################

Init $SCRIPT_PARAMS
copyInstaller

cd ~ 

echo "Installation is in process.."
getFreePort
updatePropertyFile
launchInstaller
checkStatus

postInstallSteps
