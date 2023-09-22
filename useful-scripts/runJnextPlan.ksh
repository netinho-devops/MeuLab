#!/usr/bin/ksh 
cd /bssxpinas/bss/tooladm/Scripts;
export ANT_HOME=/bssxpinas/bss/tooladm/PIL/ant;
export PATH=${PATH}:${ANT_HOME}/bin;
machNum=`echo $HOST | tr -d [a-z]`;

if [[ "$USER" = "abpwrk1" ]] then
   echo "Running Command : ant -f runJnextPlan.xml -DmachNum=${machNum}";
   ant -f runJnextPlan.xml -DmachNum=${machNum} runJnextVM
else
   if [[ `echo $USER | cut -c 1-6` != bsswrk ]] then
   
      echo "================ You must run this from a bsswrk  OR abpwrk account =================";
      exit 1;
   fi
   
   #echo "ANT HOME is $ANT_HOME";
   echo "Running Command : ant -f runJnextPlan.xml -DmachNum=${machNum}";
   ant -f runJnextPlan.xml -DmachNum=${machNum}
fi
echo "-------------- Thats all Folks!  ----------------------";