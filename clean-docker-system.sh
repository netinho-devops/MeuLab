#!/bin/bash
#
# ------------------------------------------------------------------------------- #
# Script Name:   clean-docker-system.sh
# Description:   Limpeza de recursos desnecessários usados pelo docker que possam
#                 ocupar espaço em disco.
#
# Site:          https://monitoratec.com.br
# Written by:    Anderson Oliveira
# E-mail:        anderson.oliveira@monitoratec.com.br
# Maintenance:   Anderson Oliveira
# ------------------------------------------------------------------------------- #
# Usage:
#       $ ./clean-docker-system.sh
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

echo -e "\n Cleaning disk space removing unused docker resources... \n"

# Comando para checar o valor atual do percentual usado no FileSystem /
CHECK_DISK_SPACE=$(df -h / | awk '{print $5}' | cut -d '%' -f1 | grep -v 'Use')

# Função para efetuar a limpeza de espaço em disco de acordo com os percentuais maiores que 85%
function clean_docker_resources() {


    if [ ${CHECK_DISK_SPACE} -ge 85 ];
        then
            echo -e "Espaço usado está alto !!! ${RED} ${CHECK_DISK_SPACE}% ${NORMAL} \n"

            # executa a limpeza de recursos não utilizados no Docker
            docker system prune -a -f

            echo -e "Limpeza de recursos não usados pelo Docker realizada com sucesso... \n"

        elif [ ${CHECK_DISK_SPACE} -ge 71 ] && [ ${CHECK_DISK_SPACE} -le 84 ];
            then

                echo -e "Ainda há espaço: ${YELLOW} ${CHECK_DISK_SPACE}%${NORMAL}. Mas fica esperto com o aumento ! \n"
                echo -e "Nada foi feito aqui neste momento... \n"

            else

                echo -e "Por enquanto o espaço em disco está tranquilo: ${GREEN}% ${NORMAL} \n"
                echo -e "Nada foi feito aqui..."

    fi



}

# Chamando a função de limpeza de espaço em disco de recursos não usados pelo Docker
clean_docker_resources
