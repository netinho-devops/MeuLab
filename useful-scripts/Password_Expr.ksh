#!/bin/ksh


	EMAIL_TO="jyoti.wabale@amdocs.com"
    EMAIL_TO="VIVODCCInfraMPSINT@int.amdocs.com"
	EMAIL_FROM="VIVODCCInfraMPSINT@int.amdocs.com"
	EMAIL_SUBJECT="Unix Server Password Expiration ALERT !!!"
 
 generateEmailContent()
  {
 
   echo "From:${EMAIL_FROM} "
   echo "To:${EMAIL_TO}"
   echo "Cc:${EMAIL_CC}"
   echo "Subject:${EMAIL_SUBJECT}"

   echo "Content-Type: text/html; charset=\"us-ascii\""
 
   echo "<html>"
   echo "<body>"
   echo "Hi All,"
   echo "<br>"
   echo "<br>"
   echo "<strong> <em> <h2> Below server password will get expired in few days: </strong> </em> </h2>"
   echo "<br>"
   ROWNUMBER=0
   echo "<table border='1' > <b>"
   echo "<tr bgcolor='4BACC6'>"
   echo "<td> User </td>"
   echo "<td> Host </td>"
   echo "<td> Password Expiration </td>"
   echo "</tr> </b>"

   while read line
    do

     target_User=`echo $line | cut -f1 -d " "`
     target_Host=`echo $line | cut -f2 -d " "`
     Days=`echo $line | cut -f3 -d " "`

      showGeneralInformation $target_User $target_Host $Days 

    done < Output;


   echo "</div>"
   echo "</body>"
   echo "</html>"
  }

showGeneralInformation()
 {
   if [ "`expr ${ROWNUMBER} % 2 `" = "0" ]
   then
        echo "<tr bgcolor='A5D5E2'>"
   else
        echo "<tr bgcolor='D2EAF1'>"
   fi

   echo "<td bgcolor='4BACC6'> <b> $1 </b> </td>"
   echo "<td> $2 </td>"
   echo "<td> <center> $3 days </center>  </td>"

   ROWNUMBER=`expr ${ROWNUMBER} + 1`
 }


Password_Expiration_Calc()
  {

    timestamp=`date | awk -F " " '{print $2" "$3","" "$6}'`
    target_Host=$2
    target_User=$1
    Days='0'
    Expire=`ssh ${target_User}@${target_Host} -n chage -l $target_User | grep "Password expires" | cut -d":" -f2`
       d1=$(date -d "$Expire" +%s)
       d2=$(date -d "$timestamp" +%s)
       Days=$(( (d1 - d2) / 86400 ))

#   if [ ${(( (d1 - d2) / 86400 ))} -lt '15' ] && [ ${(( (d1 - d2) / 86400 ))} -ne '0' ]
     if [ ${(( (d1 - d2) / 86400 ))} -lt '15' ]
    then
      echo $target_User $target_Host $Days >>Output
   fi
  }

touch Output
while read line
    do

     target_User=`echo $line | cut -f1 -d " "`
     target_Host=`echo $line | cut -f2 -d " "`

      Password_Expiration_Calc $target_User $target_Host
    done < Server_Info.txt;

line= cat Output | wc -l
echo $line 

if [[ -s Output ]] 
then
 generateEmailContent  | /usr/sbin/sendmail -t
fi

rm -f Output
