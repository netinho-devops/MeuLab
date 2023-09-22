#!/usr/bin/ksh
#
####################################################################################################################
# exec-backup-postgres.ksh - Executa os procedimentos de backup do banco de ados POstgreSQL - Modo Full            #
#                                                                                                                  #
# Site		: http://www.monitoratec.com.br                                                                        #
# Autor		: Anderson Ramos de Oliveira                                                                           #
# Manutenção	: Time DevOps - Monitora                                                                           #
# Versão: 1.0                                                                                                      #
#                                                                                                                  #
# -----------------------------------------------------------------------------------------------------------------#
# Este programa executa a geração de dumps do banco de dados PostgreSQL                                            #
# Ele usa como base para execução, a ferramenta pg_dump                                                            #
#                                                                                                                  #
# Exemplos:                                                                                                        #
#	$ ./exec-backup-postgres.ksh                                                                                   #
#                                                                                                                  #
#                                                                                                                  #
# Resultado esperado:                                                                                              #
#                                                                                                                  #
#   A geração de um arquivo de dump (.dmp) do banco de dados faceum                                                #
#                                                                                                                  #
#   Esse script está parametrizado buscando valores do arquivo environment.properties                              #
#    que fica no diretório conf dessa estrutura                                                                    #
#	...                                                                                                            #
#                                                                                                                  #
# Licença: GPL																									   #
# -----------------------------------------------------------------------------------------------------------------#
# Histórico                                                                                                        #
# -----------------------------------------------------------------------------------------------------------------#
#  13/11/2020 - Anderson Oliveira                                                                                  #
#    Ajustado script para usar a compressão tar do pg_dump e usar compactação gzip                                 #
#    Adicionado também o tempo médo da execução do script                                                          #
#                                                                                                     			   #
#                                                                                                     			   #
#                                                                                                     			   #
#                                                                                                     			   #
#                                                                                                     			   #
####################################################################################################################

## Prepare_Script
Prepare_Script() {

    # Posicionando o script de onde o mesmo precisa ser executado.
    cd /home/dimastec1/monitora_projects/dimastec-postgresql-backup

    ## Chamada das variáveis do environment.properties

    . conf/environment.properties

}

Main_Script() {


    echo "Iniciando procedimentos de backup full agora..."

    ## Chamada para criação do dump do banco de  dados
    PGPASSWORD="${POSTGRES_DB_PASSWORD}" \
    pg_dump -h ${POSTGRES_DB_HOST} \
    -p ${POSTGRES_DB_PORT} \
    -U ${POSTGRES_DB_USER} \
    -d ${POSTGRES_DATABASE_NAME} \
    -Ft --inserts --column-inserts -b -C \
    -f ${POSTGRES_ABSOLUTE_DUMP_PATH}/${POSTGRES_DUMP_FILE_NAME} \
    -v > ${LOG_PATH}/dump_dimastec_${POSTGRES_DATABASE_NAME}_full_$(date +%Y-%m-%d).log 2>&1 \
    && gzip -v -9 ${POSTGRES_ABSOLUTE_DUMP_PATH}/${POSTGRES_DUMP_FILE_NAME}

}

# Calculando o tempo médio de execução de script
time_elapsed() {
    SCRIPT_END_TIME=$(date +%H:%M:%S)
    TIME_ELAPSED=$(dateutils.ddiff ${SCRIPT_END_TIME} ${SCRIPT_START_TIME} -f%0H:%0M:%0S)
    print "
        Tempo de execução do script: [ ${TIME_ELAPSED} ] \n
    
    "
}

Prepare_Script
Main_Script
time_elapsed

## Identificando código de retorno da execução
exit $?
