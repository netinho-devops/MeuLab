#!/bin/bash

echo "###############################################"
echo "# Descrição: script Limpeza S3 backup jenkins #"
echo "# Autor: Luciano d Avilla Ferreira            #"
echo "# Data: 01/02/2022                            #"
echo "# Email: luciano.ferreira@monitoratec.com.br  #"
echo "###############################################"

#------------------------------------------------------------------------------------- #
# Revisão 0.1
# Autor: Anderson Oliveira
# E-mail: anderson.oliveira@monitoratec.com.br
# Data: 18/02/2023
#
#------------------------------------------------------------------------------------- #
# Melhorias realizadas:
# - Parametrização da variável WEEk com full date
# - Exibição de mensagens friendly user
# - Melhora na execução dos comandos da AWS para listar e remover os
#   arquivos do S3
#------------------------------------------------------------------------------------- #



WEEK=$(date +%F -d "365 days ago")

echo -e "Verificando se existe conteúdo a ser removido do S3"

DEAD=$(aws s3 ls s3://monitora-backups/Jenkins/mensal/ --profile default | grep "${WEEK}" | awk '{print$4}')

aws s3 rm s3://monitora-backups/Jenkins/diario/${DEAD} --profile default