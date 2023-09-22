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
    . conf/environment-restore-full.properties

}

######################################
# Alert
######################################
Message() {

    echo ""
    echo -e "${YELLOW}ATENÇÃO${NORMAL} --> Use: ${BRIGHT}${GREEN}$(basename $0) -d <data_do_backup> ${NORMAL}em formato 'YYYY-MM-DD'. \n"
    echo -e "\n"
    #sleep 10

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
                DATA_RESTORE=${OPTARG}
                echo -e "\nData escolhida:[ ${DATA_RESTORE} ]"
                ;;
            h)
                Message
                exit 1
                ;;
        esac
    done
    
    # Proceimento de restore
    
    # Cenário 01 - Valida se não foi especificado data para o backup.
    if [ $# -eq 0 ]
        then 
            Message
            exit 1
        
        # Cenário 02: Verifica se a data para restore, o nome do schame e o nome da tabela são ou não vazios
        elif  [ -n "${DATA_RESTORE}" ]
            then
                POSTGRES_DUMP_FILE_NAME=dimastec_dump_db_${POSTGRES_DATABASE_NAME}_full_${DATA_RESTORE}.dmp
                if [ -e ${POSTGRES_DUMP_HOME}/${DATA_RESTORE}/${POSTGRES_DUMP_FILE_NAME}".gz" ]
                    then
                        echo -e "Restaurando o banco de dados [ ${BRIGHT}${YELLOW}${SCHEMA_TO_RESTORE}.${TABLE_NAME}${NORMAL} ]\n"
                        
                        # Descompactando o dump escoldo
                        echo -e "Arquivo de dump encontrado: ${POSTGRES_DUMP_HOME}/${SCHEMA_TO_RESTORE}/${DATA_RESTORE}/${POSTGRES_DUMP_FILE_NAME}.gz. \nPode fazer o unzip e o restore...\n"
                        
                        # Descompactando o arquivo de dump
                        gunzip -v ${POSTGRES_DUMP_HOME}/${DATA_RESTORE}/${POSTGRES_DUMP_FILE_NAME}.gz
                        echo -e "\n"

                        # Restaurando o schema...
                        PGPASSWORD="${POSTGRES_DB_PASSWORD}" pg_restore \
                        -h ${POSTGRES_DB_HOST} -p ${POSTGRES_DB_PORT} \
                        -U ${POSTGRES_DB_USER} -d \
                        ${POSTGRES_DATABASE_NAME} ${POSTGRES_DUMP_HOME}/${DATA_RESTORE}/${POSTGRES_DUMP_FILE_NAME} -v

                        # Compactando o arquivo de volta...
                        echo -e "\nCompactando o arquivo de dump de volta...\n"
                        gzip -v -9 ${POSTGRES_DUMP_HOME}/${SCHEMA_TO_RESTORE}/${DATA_RESTORE}/${POSTGRES_DUMP_FILE_NAME}

                        echo -e "\nRestore realizado com sucesso...\n"

                    else
                        echo -e "\nSchema ou arquivo de dump não encontrado... favor verificar manualmente.\n"
                        exit 1
                fi
    
    else
        Message
        exit 1
        
    fi

# Calculando o tempo médio de execução de script
time_elapsed() {
    SCRIPT_END_TIME=$(date +%H:%M:%S)
    TIME_ELAPSED=$(dateutils.ddiff ${SCRIPT_END_TIME} ${SCRIPT_START_TIME} -f%0H:%0M:%0S)
    print "
        Tempo de execução do script: [ ${TIME_ELAPSED} ] \n
    
    "
}

time_elapsed
    
#
exit $?