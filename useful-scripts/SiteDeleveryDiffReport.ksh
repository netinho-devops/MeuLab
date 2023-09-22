#!/usr/bin/ksh
#################################################################################
# Author: Rajkumar Nayeni
# Purpose: To compare the site and DVCI storages
#
#################################################################################

EnvironmentVariables()
{
SourceDir="${1}"
TargetDir="${2}" 
FROM_MAIL="VIVODCCInfraMPSINT@int.amdocs.com"
TO_MAIL="vinayp@amdocs.com"
MAIL_SUBJECT='Difference Report'
STAGE_USER='amdocs'
STAGE_HOST='10.33.200.219'
SITE_HOST='vlty0532sl'
SITE_USER='vivtools'
}

mailHeader()
{
echo "From:${FROM_MAIL} "
echo "To:${TO_MAIL} "
echo "Subject:${MAIL_SUBJECT}"

echo "Content-Type: text/html; charset=\"us-ascii\""

 cd ${SourceDir}

 echo "<html>
<head>
<style type="text/css">
td, th
{
font-size:1em;
border:1px solid #98bf21;
padding:3px 7px 2px 7px;
text-align:center;
}
th
{
font-size:1.1em;
text-align:left;
padding-top:5px;
padding-bottom:4px;
background-color:#A7C942;
color:#ffffff;
text-align:center;
}
tr.alt td
{
color:#000000;
background-color:#EAF2D3;
text-align:center;
}
</style>
</head>
<body><div><table border='1'>"
 echo "<tr><th>DVCI File Name</th><th colspan='2'>DVCI cksum </th><th>Site File Name</th> <th colspan='2'>SITE cksum </th> </tr>"

}

mailTail()
{
echo "</div></table>"
echo "<div>"
echo "Regards,"
echo "<br>"
echo "Rajkumar Nayeni"
echo "</div>"
 echo "</body></html>"
}

prepareMailContent()
{

mailHeader

if [ -z $SITE_USER ]
then
ssh ${SITE_USER}@${SITE_HOST} ' . ./.profile >/dev/null 2>&1 ; find ${TargetDir} -type f | xargs cksum ' | sort  > /tmp/Site_checksum.txt
else
ssh ${STAGE_USER}@${STAGE_HOST} "ssh ${SITE_USER}@${SITE_HOST} ' . ./.profile >/dev/null 2>&1 ; find ${TargetDir} -type f | xargs cksum ' " | sort  > /tmp/Site_checksum.txt
fi
find ${SourceDir} -type f | xargs cksum | sort  > /tmp/DVCI_checksum.txt

for fileName in ` find ${SourceDir} -type f `
do
cksumValue=`grep "${fileName}$" /tmp/DVCI_checksum.txt`
targetLocFile=`echo "${fileName}$" | sed -e "s#${SourceDir}#${TargetDir}#g"`
sitecksumValue=`grep ${targetLocFile} /tmp/Site_checksum.txt`
if [[ "`echo ${cksumValue} | cut -d' ' -f1`" != "`echo ${sitecksumValue} | cut -d' ' -f1`" ]] || [[ "`echo ${cksumValue} | cut -d' ' -f2`" != "`echo ${sitecksumValue} | cut -d' ' -f2`" ]]
 then
         echo "<tr style='color:red'>"

echo "<td style='width:30px;'> `echo ${cksumValue} | cut -d' ' -f3` </td>"
echo "<td> `echo ${cksumValue} | cut -d' ' -f1` </td>"
echo "<td> `echo ${cksumValue} | cut -d' ' -f2` </td>"
echo "<td style='width:30px;'> `echo ${sitecksumValue} | cut -d' ' -f3` </td>"
echo "<td> `echo ${sitecksumValue} | cut -d' ' -f1` </td>"
echo "<td> `echo ${sitecksumValue} | cut -d' ' -f2` </td>"
echo "</tr>"
fi
done

mailTail

}

EnvironmentVariables ${1} ${2}
echo "Preparing Email Content please wait until complete ....."
prepareMailContent | /usr/sbin/sendmail -t
echo "Sent generated report please check and procced ...."


