#!/bin/ksh
Env_num=$1
Dump_location=$2
#This file was generated by ADDM

cd `dirname $0`
ssh tgrabp@illin3333 -o StrictHostKeyChecking=no -n  ". ./.profile 2>/dev/null;\${TIGER_HOME}/addmcli/adb_importenv --login=/bssxpinas/bss/tooladm/Scripts/ImportRessorse/loginfile --dump=${Dump_location}/BSSAPPO5_BSSABP1.dmp.gz  --tablelist=/bssxpinas/bss/tooladm/Scripts/ImportRessorse/tablesfile --arealist=/bssxpinas/bss/tooladm/Scripts/ImportRessorse/areasfile --modulelist=/bssxpinas/bss/tooladm/Scripts/ImportRessorse/moduleslist ${Env_num}"

