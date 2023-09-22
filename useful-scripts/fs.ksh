#!/bin/ksh
# execute as such
# fs.ksh <filesystem> <Disk_Usage_percent> 
FS=$1
DU=$2

if [[ $(grep -c 'tooladm' /etc/passwd) != 0 ]]
then
. ~tooladm/.profile
Perl_script=~tooladm/Scripts/FS_Check/fs.pl
$Perl_script $FS $DU 
exit
elif [[ $(grep -c 'tooladm' /etc/passwd) != 0 ]]
then
. ~tooladm/.profile
Perl_script=~tooladm/Scripts/FS_Check/fs.pl
$Perl_script $FS $DU
exit
fi
