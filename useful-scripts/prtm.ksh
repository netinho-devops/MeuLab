#!/usr/bin/ksh 

#
# Script to run Post Release Topology Manipulation
# Writer : Harshal Shah
# Date : 02-Apr-2014
# Listening to : Seven Nation Army - White Stripes
#

#
# Function to print error and exit
#
errExit()
{
   echo "[ERROR] : " $1 
   exit 1;
}


#
# Main Execution starts here
# Prelim Check 1 : Check if running from BN_ folder 
#

myLoc=`pwd`;

#
# If the input file is not CXPI file then script should run from BN folder else for CXPI it would run from $HOME/storage_root/packages folder of 
# ABP env
#

      if [[ `basename $myLoc | cut -c -3` != BN_ ]] then 
         errExit "Script not running from BN_ location but from $myLoc ";
      fi

#
# Prelim Check 2 : Checking input file 
#
if [[  ! -f $1 ]] then
    errExit "Input file $1 does not exist. Exiting ";
fi

#
# Sourcing input file to get all vars
#
. $1

#
# Prelim Check 3 : Check if any reuired variable is missing
#

if [[ "${excelFile}" = "" || "${baseTopology}" = "" || "${packagePrefix}" = "" || "${generateTopology}" = "" ]] then
    errExit "One of the following required parameters [excelFile baseTopology packagePrefix generateTopology] is BLANK in input file $1 ";
fi

#
# Prelim Check 4 : Check if main product jar is present 
#
prodJar=`ls ${packagePrefix}*.jar | grep -v ClientKit | tail -n 1`;
xdkJar=`ls XDK/${packagePrefix}*.jar | tail -n 1`;
if [[ ! -f ${prodJar} ]] then
    errExit "Package with prefix ${packagePrefix} is not present in this directory. Exiting.";
fi

#
# Prelim Check 5 : Check if XPI installer and required scripts are present
#
for f in installer installer/bin/xpi_topology_manipulation.sh installer/bin/packager/injectPackage.sh
do
if [[ ! -a $f ]] then
    errExit "XPI installer folder or script $f is missing.";
fi 
done

#
# Prelim Check 6 : Check if the jar and excel exist in package, if so get their path.
# 

excelFile=`jar tvf ${prodJar} | grep -w ${excelFile} | head -n 1 | awk '{print $8}'`;
baseTopology=`jar tvf ${prodJar} | grep -w ${baseTopology} | head -n 1 | awk '{print $8}'`;

echo "New value of excelFile is ${excelFile} and baseTopology is ${baseTopology}";


mkdir deleteme;

#
# Extracting Excel and BASE topology from product package
#
cd deleteme;
jar xvf ../${prodJar} ${excelFile} ${baseTopology};
if [[ $? -ne 0 ]] then 
    errExit "Extraction of excel file and BASE topology from jar failed. Exiting";
fi

cd ..;

#
# Begin topology manipulation  | Song changed to Latigazo - Daddy Yankee
#
for rec in `echo ${generateTopology} | sed 's/;/ /g'`
do
xlSheet=`echo $rec | cut -d":" -f1`;
manTop=`echo $rec | cut -d":" -f2`;
echo  " Running Manipulation on XL sheet $xlSheet to generate topology $manTop ";
./installer/bin/xpi_topology_manipulation.sh --mem huge -m -p ${prodJar} -t ./deleteme/${baseTopology} -f ./deleteme/${excelFile} -s ${xlSheet} -tt ./${manTop}
if [[ $? -ne 0 ]] then 
    errExit "Manipulation of topology from BASE topology for generation of ${manTop} failed. Exiting";
fi
#
# Injecting generated topologies into product package and XDK package.
# Checking if file already exists in package
#
if [[ `jar tvf ${prodJar} | grep product/template-topologies/${manTop}` = "" ]] then
   injectMode="-add";
else 
   injectMode="-update";
fi


echo "-------- Injecting topology ${manTop} to package ${prodJar} AND ${xdkJar} in $injectMode mode";
./installer/bin/packager/injectPackage.sh -pkg ${prodJar} ${injectMode} product/template-topologies/${manTop} ./${manTop}
./installer/bin/packager/injectPackage.sh -pkg ${xdkJar} ${injectMode} product/template-topologies/${manTop} ./${manTop}

done
rm -rf deleteme ./installer/work;


