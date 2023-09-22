#!/usr/bin/ksh
clear;
echo "You are at location `pwd`";
echo "Are you sure you want files in this location? (Y/N)";
read usrInp;
if [[ $usrInp = Y || $usrInp = y ]] then
echo "Proceeding with scp";
else 
echo "Exiting. Please cd to desired location and then run this script again.";
exit 1;
fi

if [[ ! -a $1 ]] then
   echo "Input File $1 is not available. Try giving absolute path of input file.";
   echo "Exiting.";
   exit 1;
fi

for f in `cat $1`
do
scp apsdlv@illin1132:${f} .
done

