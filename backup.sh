#!/bin/bash

echo "###############################################"
echo "# Descrição: script de restore ALL do jenkins #"
echo "# Autor: Luciano d Avilla Ferreira            #"
echo "# Data: 17/01/2022                            #"
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
# - Colocação do nome de arquivo em variável
# - Reformulação da variável DATE
# - Por questões de espaço em disco foi adicionado a remoção arquivo após a cópia
#   para o bucket S3 da AWS da monitora
#------------------------------------------------------------------------------------- #

DATE=$(date +%F)
FILE_NAME="backup_jenkins_${DATE}.tar.gz"

cd /var/lib/jenkins

echo -e "\nFazendo a cmpactação da estrutura do Jenkins..\n"

tar -czvf ${FILE_NAME} jobs/ logs/ nodes/ plugins/ secrets/ users/ userContent/ *.xml # --exclude="workspace" --exclude="builds"

echo -e "\n Movendo o conteúdo compactado para o FileSystem /backups...\n"
mv ${FILE_NAME} /backups
cd /backups

echo -e "\n Copiando o conteúdo compactado para o bucket S3 da AWS Monitora....\n"

aws s3 cp ${FILE_NAME} s3://monitora-backups/Jenkins/diario/ --profile default

#Verifica se o resultado da execução do comando anterior terminou ou não em sucesso...
if [ $? -eq 0 ];
    then
        echo -e "\n Removendo o arquivo de backup criado: ${FILE_NAME} para evitar problemas de espaço...\n"
        rm -rfv ${FILE_NAME}
    else
        echo -e "\n Ocorreu algum problema com a cópia do arquivo para o S3. Por favor verificar...\n"

fi
