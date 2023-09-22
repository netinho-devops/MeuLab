#!/usr/bin/ksh

########################################################################################################################
# exec-restore-full-postgres.ksh - Executa os procedimentos de restore do banco de ados POstgreSQL                     #
#                                                                                                                      #
# Site		: http://www.monitoratec.com.br                                                                            #
# Autor		: Anderson Ramos de Oliveira                                                                               #
# Manutenção	: Time DevOps - Monitora                                                                               #
# Versão: 1.0                                                                                                          #
#                                                                                                                      #
# ---------------------------------------------------------------------------------------------------------------------#
# Este programa executa o restore full do dump do banco de dados PostgreSQL                                            #
# Ele usa como base para execução, a ferramenta pg_restore                                                             #
#                                                                                                                      #
# Exemplos:                                                                                                            #
#	$ ./exec-backup-full-postgres.ksh                                                                                  #
#                                                                                                                      #
#                                                                                                                      #
# Resultado esperado:                                                                                                  #
#                                                                                                                      #
#   O restore do banco de dados faceum                                                                                 #
#                                                                                                                      #
#   Esse script está parametrizado buscando valores do arquivo environment.properties                                  #
#   que fica no diretório conf dessa estrutura                                                                         #
#	...                                                                                                                #
#                                                                                                                      #
# Licença: GPL                                                                                                         #
#                                                                                                                      #
#																													   #
#                                                                           										   #
##########################################################################################################33############

######################################
# Colors
######################################
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)
export WHITE=$(tput setaf 7)
export BRIGHT=$(tput bold)
export NORMAL=$(tput sgr0)

## Definindo funções para as chamadas no script

Prepare_Script() {


    cd /home/dimastec1/monitora_projects/dimastec-postgresql-backup
    . conf/environment-schema.properties

}

######################################
# Alert
######################################
Message() {

    echo ""
    echo -e "${YELLOW}ATENÇÃO${NORMAL} --> Use: ${BRIGHT}${GREEN}$(basename $0) -d <data_do_backup> ${NORMAL}em formato 'YYYY-MM-DD'. \n Caso não especifique data, será realizado o restore com o dump realizado no dia anterior"
    echo ""
    sleep 10

}

Prepare_Script

######################################
# MAIN PROCESS
######################################

# Escolhendo as opções para ser feito o restore do backup
    while getopts 'd:h' OPTION
    do
        case ${OPTION} in
            d)
                DATA_BACKUP=${OPTARG}
                echo -e "Data escolhida: ${DATA_BACKUP}\n"
                RestoreFullDB_by_date
                ;;
            h)
                Message
                echo "Escolhi essa opção..."
                exit 1
                ;;
        esac
    done
    if [ $# -eq 0 ]
        then 
            Message
            echo "RestoreFullDB_by_previous_date"
    fi

exit $?