#!/bin/ksh

echo "#!/bin/ksh" > ~/.profile
echo "set -o emacs" >> ~/.profile
echo "MYHOST=`hostname`" >> ~/.profile
echo "MYHOME=`dirname ${HOME}`" >> ~/.profile
echo "export ORACLE_HOME=/oravl01/oracle/12.1.0.2" >> ~/.profile
echo "export JAVA_HOME=/usr/java/jdk1.8.0_31" >> ~/.profile
echo "export PS1='${USER}@${MYHOST}:~${PWD##${MYHOME}/}>'" >> ~/.profile
echo "export PATH=${JAVA_HOME}/bin:${ORACLE_HOME}/bin:${PATH}" >> ~/.profile
echo "alias ll='/bin/ls -Alrt'" >> ~/.profile
echo "alias psu='/bin/ps -fu ${USER}'" >> ~/.profile
echo "alias omnis='cd $HOME/JEE/LightSaberDomain/scripts/LightSaberDomain/omni_LSJEE'" >> ~/.profile
echo "alias omnir='omnis; ./startomni_LSJEE.sh'" >> ~/.profile
echo "alias omnil='cd $HOME/JEE/LightSaberDomain/logs/LightSaberDomain/omni_LSJEE'" >> ~/.profile
echo "alias omnit='cd $HOME/JEE/LightSaberDomain/logs/LightSaberDomain/omni_LSJEE; tail -f `ls -tr weblogic.*| tail -1`'" >> ~/.profile
echo "alias omniv='cd $HOME/JEE/LightSaberDomain/logs/LightSaberDomain/omni_LSJEE; less `ls -tr weblogic.*| tail -1`'" >> ~/.profile
echo "export OMNI_APP_HOST=`hostname`" >> ~/.profile
echo "export OMNI_APP_USER=$USER" >> ~/.profile

. ~/.profile
