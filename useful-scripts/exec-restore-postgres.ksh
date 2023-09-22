#!/usr/bin/ksh
#
# exec-restore-postgres.ksh - Executa os procedimentos de restore do banco de ados PostgreSQL
#
# Site		: http://www.monitoratec.com.br
# Autor		: Anderson Ramos de Oliveira
# Manutenção	: Time DevOps - Monitora
#
# ---------------------------------------------------------------
# Este programa executa a geração de dumps do banco de dados PostgreSQL
# Ele usa como base para execução, a ferramenta pg_dump
#
# Exemplos:
#	$ ./exec-backup-postgres.ksh
# 
#
# Resultado esperado:
#   
#   A geração de um arquivo de dump (.dmp) do banco de dados faceum
#
#   Esse script está parametrizado buscando valores do arquivo environment.properties 
#    que fica no diretório conf dessa estrutura
#	...
#
# Licença: GPL
#

## Chamada das variáveis do environment.properties

. ../conf/environment.properties
