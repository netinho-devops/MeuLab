#!/usr/bin/ksh

########################################################################################################################
# exec-backup´schema-postgres.ksh - Executa os procedimentos de backup do banco de ados POstgreSQL por cada schema     #
#                                                                                                                      #
# Site		: http://www.monitoratec.com.br                                                                            #
# Autor		: Anderson Ramos de Oliveira                                                                               #
# Manutenção	: Time DevOps - Monitora                                                                               #
# Versão: 1.0                                                                                                          #
#                                                                                                                      #
# ---------------------------------------------------------------------------------------------------------------------#
# Este programa executa a geração de dumps do banco de dados PostgreSQL                                                #
# Ele usa como base para execução, a ferramenta pg_dump                                                                #
#                                                                                                                      #
# Exemplos:                                                                                                            #
#	$ ./exec-backup=schema-postgres.ksh                                                                                #
#                                                                                                                      #
#                                                                                                                      #
# Resultado esperado:                                                                                                  #
#                                                                                                                      #
#   A geração de um arquivo de dump (.dmp) do banco de dados faceum                                                    #
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


## Definindo funções para as chamadas no script

Prepare_Script() {


    cd /home/dimastec1/monitora_projects/dimastec-postgresql-backup
    . conf/environment-schema.properties

}

## Efetivando o processo de backup do banco

Main() {


        echo "Iniciando procedimentos de backup agora..."

        ## Chamada para criação do dump do banco de  dados

        for POSTGRES_DB_SCHEMA_NAME in \
            $(echo -e "SELECT n.nspname AS "Name" 
                        FROM pg_catalog.pg_namespace n 
                        WHERE n.nspname "\!~" '^pg_' 
                        AND n.nspname <> 'information_schema' 
                        ORDER BY 1 asc;" \
                        | PGPASSWORD="${POSTGRES_DB_PASSWORD}" \
                        psql -h ${POSTGRES_DB_HOST} -p ${POSTGRES_DB_PORT} -U ${POSTGRES_DB_USER} -d ${POSTGRES_DATABASE_NAME} -t);
            do
                POSTGRES_DUMP_FILE_NAME=dimastec_dump_db_${POSTGRES_DATABASE_NAME}_${POSTGRES_DB_SCHEMA_NAME}_$(date +%Y-%m-%d).tar
                echo -e "Nome do schema: " ${POSTGRES_DB_SCHEMA_NAME}
                
                # Cenário 01 - Verifica se o diretório do schema, o diretório da data e o arquivo existem
                # em caso positivo, não terá ação pois o backup já foi feito angteriormente

                if [ -e ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER}/${POSTGRES_DUMP_FILE_NAME}".gz" ]

                    then
                        echo -e "Arquivo de backup já existe. Sem ação neste momento..."

                    # Cenário 02 - Se o arquivo de dump não existe, verifica se existem o diretório com o nome do schema e o diretório da data de quando o dump foi realizadoo
                    # Em caso positivo, é gerado o dump do schema e na sequência ele é compactado em formato gzip com nível de compressão 9 - A mais alta

                    elif [ -d ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER} ]
                        then
                            echo -e "Diretório já existe... Gerando dump do schema " ${POSTGRES_DB_SCHEMA_NAME}
                            $(PGPASSWORD="${POSTGRES_DB_PASSWORD}" \
                            pg_dump -h ${POSTGRES_DB_HOST} -p ${POSTGRES_DB_PORT} \
                            -U ${POSTGRES_DB_USER} -d ${POSTGRES_DATABASE_NAME} \
                            -n ${POSTGRES_DB_SCHEMA_NAME} --inserts --column-inserts -b -Ft \
                            -f ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER}/${POSTGRES_DUMP_FILE_NAME} -v \
                            && gzip -v -9 ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER}/${POSTGRES_DUMP_FILE_NAME}) 
                    
                    # Cenário 03 - Se o diretório da data de quando o dump foi gerado não existir, verifica se existe o diretório com o nome do schema
                    # Em caso positivo, cria o diretório de data, gera o dump e na sequência, compacta o arquivo em formato gzip com o nível de compressão 9 - A mais alta

                    elif [ -d ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME} ]
                            then
                                echo -e "Diretório do schema já existe. Gerando diretório de data para também gerar o dump..."
                                $(mkdir -p ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER})
                                $(PGPASSWORD="${POSTGRES_DB_PASSWORD}" \
                                pg_dump -h ${POSTGRES_DB_HOST} -p ${POSTGRES_DB_PORT} \
                                -U ${POSTGRES_DB_USER} -d ${POSTGRES_DATABASE_NAME} \
                                -n ${POSTGRES_DB_SCHEMA_NAME} --inserts --column-inserts -b -Ft \
                                -f ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER}/${POSTGRES_DUMP_FILE_NAME} -v \
                                && gzip -v -9 ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER}/${POSTGRES_DUMP_FILE_NAME})

                    # Cenário 04 - Caso não exista nada, é criado todos os diretórios - schema_name + diretório de data de quando o dump será gerado,
                    # gera o dump e na sequência, o arquivo é compactado em formato gzip com o nível de compressão 9 - A mais alta        
                    
                    else
                                echo -e "Criando estrutura de backup: " ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER}
                                $(mkdir -p ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER})
                                $(PGPASSWORD="${POSTGRES_DB_PASSWORD}" \
                                pg_dump -h ${POSTGRES_DB_HOST} -p ${POSTGRES_DB_PORT} \
                                -U ${POSTGRES_DB_USER} -d ${POSTGRES_DATABASE_NAME} \
                                -n ${POSTGRES_DB_SCHEMA_NAME} --inserts --column-inserts -b -Ft \
                                -f ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER}/${POSTGRES_DUMP_FILE_NAME} -v \
                                && gzip -v -9 ${POSTGRES_DUMP_HOME}/${POSTGRES_DB_SCHEMA_NAME}/${POSTGRES_DB_SCHEMA_DUMP_DATE_FOLDER}/${POSTGRES_DUMP_FILE_NAME}) 
                fi
        done


}

# Calculando o tempo médio de execução de script
time_elapsed() {
    SCRIPT_END_TIME=$(date +%s)
    TIME_DIFF=$(expr ${SCRIPT_END_TIME} - ${SCRIPT_START_TIME})
    TIME_ELAPSED_MINS=$(expr ${TIME_DIFF} / 60)
    TIME_ELAPSED_HOURS=$(expr ${TIME_DIFF} / 3600)
    TIME_ELAPSED_SECONDS=$(expr ${TIME_DIFF} % 60)
    print "
    Time elapsed: [ ${TIME_ELAPSED_HOURS}:${TIME_ELAPSED_MINS}:${TIME_ELAPSED_SECONDS} ] \n
    "
}

# Efetuando procedimentos pós backup - Apresentando a mensagem ao usuário

After_Backup() {

    echo -e "Backup dos schemas do banco realizado com sucesso...\n"

}

Prepare_Script
Main
time_elapsed
After_Backup

## Identificando código de retorno da execução
exit $?
