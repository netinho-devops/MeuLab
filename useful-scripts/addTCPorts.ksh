#!/usr/bin/ksh

set -A PORTS `grep "=[0-9][0-9]*" ${HOME}/.w.ini.pre.env | cut -d"=" -f2 | sort -n | tail -n 20`

for i in {0..$((${#PORTS[@]}-1))}
do
   if [[ ! $((${PORTS[$i]} + 1)) -eq ${PORTS[$(($i + 1 ))]} ]] then
      echo "===> Highest number is series = ${PORTS[$i]}"
      break
   fi
done
nextPort=${PORTS[$i]};
for n in 1005 1006 1009 1012
do
nextPort=$(( $nextPort + 1));
echo "export TC3_PORT_EXTERNAL_${n}_SY_BW=${nextPort}" >> ${HOME}/.local.ini
nextPort=$(( $nextPort + 1));
echo "export TC3_PORT_EXTERNAL_${n}_ACCR24=${nextPort}" >> ${HOME}/.local.ini
done