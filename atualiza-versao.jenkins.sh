#!/bin/bash
#
# ------------------------------------------------------------------------------- #
# Script Name:   atlualiza-versao-jenkins.sh
# Description:   Fornece a atualização da versão do Jenkins para a mais recente
#                 
#
# Site:          https://monitoratec.com.br
# Written by:    Anderson Oliveira
# Team:          DevSecOps
# E-mail:        anderson.oliveira@monitoratec.com.br
# Maintenance:   Anderson Oliveira
# ------------------------------------------------------------------------------- #
# Usage:
#       $ ./atualiza-versao-jenkins.sh
# ------------------------------------------------------------------------------- #
# Bash Version:
#              GNU bash, version 4.2.46(2)-release (x86_64-koji-linux-gnu)
# -----------------------------------------------------------------#
# History:       v1.0 06/02/2023 Anderson Oliveira:
#                - Desenvolvimento do script e execução do mesmo
# ------------------------------------------------------------------------------- #
# Thankfulness:
#
# ------------------------------------------------------------------------------- #

RED="\e[33;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33;40m"
NORMAL="\e[0m"

JENKINS_CURRENT_VERSION=$(java -jar /usr/share/java/jenkins.war --version)
JENKINS_PORT=8080

echo -e "\n Versão atual do Jenkins: ${YELLOW}${JENKINS_CURRENT_VERSION}${NORMAL} \n"
echo -e "*** Atualização de versão do Jenkins. Por favor, aguarde... *** \n"


# Iniciando o processo de atualização do jenkins para a última versão liberada

function atualiza_jenkins() {

    # |Parando o serviço jenkins
    echo -e "\n Parando o serviço Jenkins... \n"
    systemctl stop jenkins

    #Realizando backup da versão atual do jenkins - caso seja necessário fazer rollback
    echo -e "\n Realizando backup da versão atual do jenkins - caso seja necessário fazer rollback... \n"

    cd /usr/share/java
    mv -v jenkins.war jeknkins.war_backup_$(date +%F)

    echo -e "\n Backup realizado com sucesso. Baixado nova versão... aguarde ! \n"
    wget http://updates.jenkins-ci.org/latest/jenkins.war

    echo -e "\n Iniciando o serviço do Jenkins. Por favor aguarde... \n"
    systemctl start jenkins
    
    #Verifica se a porta do jenkins está em estado de listening
    JENKINS_CURRENT_STATUS=$(lsof -i:${JENKINS_PORT} | awk '{print $10}' | tr -d '(' | tr -d ')' | grep 'LISTEN')
    if [ "${JENKINS_CURRENT_STATUS}" = "LISTEN" ];
        then
            echo -e "\n Serviço do Jenkins foi reiniciado com sucesso...\n"
            
            JENLINS_LATEST_VERSION=$(java -jar /usr/share/java/jenkins.war --version)
            echo -e "\n Nova versão do jenkins: ${GREEN}${JENLINS_LATEST_VERSION}${NORMAL} \n"
            cd ${HOME}

        else 
            echo -e "Ocorreu algum problema com o startup do jenkins. Verificar...\n"
            exit 1
    fi

}
atualiza_jenkins
