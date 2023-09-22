# Solução de backup - Dimastec

## Introdução

<p align="justify">

Este projeto tem como objetivo apresentar a solução de backup de banco de dados para o cliente Dimastec
A solução foi projetada inicialmente para gerar dumps do banco de dados em modo full e por cliente (schema)
Dessa forma, foram elaborados scripts para execução destes procedimentos para backup e também de restore

Os scripts de backup são agendados no crontab do servidor de banco de dados para serem rodados todos os dias à meia-noite

</p>

## Pré-Requisitos necessários

Para implementação da solução de backup de banco de dados, é necessário a instalação das seguintes ferramentas

* Git
* ksh - Korn Shell
* dateutils

## Arquitetura da solução de baclup / restore


A arquitetura da solução de backup e restore, está dividida na estrura a seguir:

* conf --> Contém os arquivos de parametrização da solução. Dadps como por exemplo, nome do banco de dados, porta padrão, etc...

* logs --> Contém os logs de execução dos scripts de backup executados pelo agendador crontab. Recomendamos que ao efetivar um procedimento de restore,
           os resultados seajm apontados para arquivps neste diretório para acompanhamento.

* scripts --> Contém os arquivos de execução dos procedimentos de backup e restore do banco de dados.

* /home/dimastec/dimastec_backup_db/backup-full --> Contém os diretórios relativos as datas onde foram gerados os arquivos de backup do banco de dados. Esses diretórios gerados tem o formato *YYYY-MM-DD*

* /home/dimastec1/dimastec_backup_db/backup-schemas --> Contém ps diretórios de cada schema (cliente) e em cada um destes diretórios de clientes são criados novos diretórios com as data de quando foram gerados os arquivos de backup. Eles seguem o mesmo padrão de criação do backup full, ou seja *YYYY-MM-DD*

## Instalação

Para realizar a instalação siga os passos abaixo no servidor de banco de dados:

1. Atualize a lista de repositórios:
```# apt update```
2. Instale o git. Caso ele não esteja presente no servidor de banco de dados:
```# apt install git -y ```
3. Instale o ksh (korn shell):
```# apt install ksh -y```
4. Instale o dateutils:
```# apt install dateutils -y ```
5. Crie um diretório em */home* com o nome de *dimastec1* - Somente se ele não existir:
```# mkdir /home/dimastec1 ```
6. Em */home/dimastec1*, crie o diretório *monitora_projects*
```# mkdir /home/dimastec1/monitora_projects ```
7. Dentro do diretório */home/dimastec1*, crie o diretório *dimastec_backup_db* e mais 2 subdiretórios: *backup-full* e *backup-schemas*:
  1. ```# mkdir -p /home/dimastec1/dimastec_backup_db/backup-full```
  2. ```# mkdir -p /home/dimastec1/dimastec_backup_db/backup-schemas ```
8. Dentro do diretório */home/dimastec1/monitora_projects*, inicialize o git. Execute 
```# git init ```
9. Faça um clone do repositório da dimastec através do git da monitora. Execute: 
```# git clone git@git.monitoratec.com.br:anderson.oliveira/dimastec-postgresql-backup.git ```

### Para o ambiente de homologação

1. Acesse o diretório: /home/dimastec1/monitora_projects. faça o pull do branch de homologação. Execute: 
```# git pull origin homolog ```
2. Copie o arquivo de agendamento do crontab: *dimastec-postgresql-backup-homolog* para o diretório */etc/cron.d*

### Para o amiente de produção

1. No diretório: /home/dimastec1/monitora_projects. faça o pull do branch master. Execute: 
```# git pull origin master ```
2. Copie o arquivo de agendamento do crontab: dimastec-postgresql-backup-prod para o diretório /etc/cron.d

## Executando o backup manualmente

### Ambiente de homologação - backup full

1. Acesse o diretório: */home/dimastec1/monitora_projects/dimastec-postgresql-backup/scripts* e execute:
```# ./exec-backup-postgres.ksh```

### Ambiente de homologação - backup por cliente (schema)

1. Acesse o diretório */home/dimastec1/monitora_projects/dimastec-postgresql-backup/scripts* e execute:
```# ./exec-backup-schema-postgres.ksh```

### Ambiente de produção - backup full

1. Acesse o diretório: */home/dimastec1/monitora_projects/dimastec-postgresql-backup/scripts* e execute:
```# ./exec-backup-postgres.ksh```

### Ambiente de produção - backup por cliente (schema)

1. Acesse o diretório */home/dimastec1/monitora_projects/dimastec-postgresql-backup/scripts* e execute:
```# ./exec-backup-schema-postgres.ksh```


## Executando o restore manualmente

Nos casos, em que houver um desastre no servidor de baanco de dados, tais como, perda de schemas, tabbela truncada, o banco de dados foi dropado,
existe a opção de ser feito o restore de forma full ou especificamente por schema.

### Executando restore full

No procedimento de restore full, através da informação de parâmetros adicionais obrigatórios, as validações serão realizadas pelo script de restore. Em seguida, o arquivo é descompactado, realizado o restore e ao finalizar, o arquivo de backup é compactado novamente caso ele queira ser usado em alguma outra ocasião.


#### Atenção

Somente quando ocorre a perda total do banco de dados (base deletada / dropada), é necessário uma intervenção manual diretamente no PostgreSQL efetivando a criação da base de dados maunalmente antes do processo de restore ser executado.
Para que isso ocorra, siga este roteiro:

1. Logue na base de dados com o usuário postgres e execute:
```# CREATE DATABASE <nomda_da_base_de_dados>; ```

## Para restore do backup de dados por schema (cliente)

1. No diretório de *scripts* da solução de bakcup, execute:
``` # ./exec-restore-schema-postgres.ksh ```

Neste script são requeridos alguns parâmtros que são:

* -d <data_do_backup> --> Esse parâmetro precisa ser informado ao script em formato "YYYY-MM-DD"
* -s <schema_name> --> É necessário informar neste parâmetro, o nome do schema a ser restaurado

##### Parâmetros opcionais

1. Existem parâmetros que podem ser usados opcionalmente em um procedimento de restore por schema:

* -t <tabela_específica_do_schema> --> Quando ocorre um problema apenas com uma tabela específica do schema e não há a necessidade de ser feito o restore total do schema, pode optar pela tabela específica a ser restaurada.
* -h --> Exibe uma mensagem de ajuda, mostrando os formatos de como o script pode ser executado.

## Para restore do backup de dados full

Em situações em que o banco de dados foi totalmente perdido, poderá ser feito o restore full do banco de dados. Para realizar este procedimento, siga os passos abaixo:

1. No diretório de *scripts* da solução de bakcup, execute:
```# ./exec-restore-full-postgres.ksh ```

Neste script há um parâmetro requerido para execução do restore full:

* -d <data_do_backup> --> Nesse parâmetro, é necessário informar uma data para este restore. Lembrando-se sempre do formato: "YYYY-MM-DD"

Opcionalmente, use o parâmetro:

* -h --> Para exibir mensagem de ajuda para verificar o formato em que poderá ser executado o script,
