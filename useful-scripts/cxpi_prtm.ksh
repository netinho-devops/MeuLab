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
   rm -rf ${HOME}/storage_root/packages/deleteme ${HOME}/installer/work;
   exit 1;
}

export JAVA_HOME=`grep "cxpi.JAVA_HOME=" ${HOME}/genesisTmpDir/line_cxpi.properties | cut -d"=" -f2`;
export ANT_HOME=`grep "cxpi.ANT_HOME=" ${HOME}/genesisTmpDir/line_cxpi.properties | cut -d"=" -f2`;
export PATH=${PATH}:${JAVA_HOME}/bin:${ANT_HOME}/bin;

#
# Prelim Check 2 : Checking input file 
#
if [[  -z $1 ]] then
    errExit "CXPI Package prefix not provided. Exiting ";
fi

cd ${HOME}/storage_root/packages;
packagePrefix=$1;
prodJar=`ls ${packagePrefix}*.jar | tail -n 1`;
echo "============== Extracting cxpi_prtm.properties file from package $prodJar ================";
mkdir $$;
cd $$;
ipFilePath=`jar tvf ../$prodJar | grep cxpi_prtm.properties | head -n 1 | awk '{print $8}'`;
jar xvf  ../$prodJar $ipFilePath
cp $ipFilePath ${HOME}/storage_root/packages
cd ${HOME}/storage_root/packages;
rm -rf $$;
#
# Sourcing input file to get all vars
#
. ./cxpi_prtm.properties

#
# Prelim Check 3 : Check if any reuired variable is missing
#

if [[ "${excelFile}" = "" || "${baseTopology}" = "" || "${packagePrefix}" = "" || "${generateTopology}" = "" ]] then
    errExit "One of the following required parameters [excelFile baseTopology packagePrefix generateTopology] is BLANK in input file $1 ";
fi

#
# Prelim Check 4 : Check if main product jar is present 
#


if [[ ! -f ${prodJar} ]] then
    errExit "Package with prefix ${packagePrefix} is not present in this directory. Exiting.";
fi

#
# Prelim Check 5 : Check if XPI installer and required scripts are present
#
for f in ${HOME}/installer ${HOME}/installer/bin/xpi_topology_manipulation.sh ${HOME}/installer/bin/packager/injectPackage.sh
do
if [[ ! -a $f ]] then
    errExit "XPI installer folder or script $f is missing.";
fi 
done
chmod -R 755 ${HOME}/installer/*;
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
cd ${HOME}/storage_root/packages;
${HOME}/installer/bin/xpi_topology_manipulation.sh --mem huge -m -p ${HOME}/storage_root/packages/${prodJar} -t ${HOME}/storage_root/packages/deleteme/${baseTopology} -f ${HOME}/storage_root/packages/deleteme/${excelFile} -s ${xlSheet} -tt ${HOME}/storage_root/packages/${manTop}
if [[ $? -ne 0 ]] then 
    errExit "Manipulation of topology from BASE topology for generation of ${manTop} failed. Exiting";
fi

#
# Finding parent folder of Portfoio jar
#
injectJar=`ls -l ${packagePrefix}*.jar | cut -d">" -f2`;
if [[ "$injectJar" = "" ]] then
   errExit " ${prodJar} is not a soft link.";
   
fi

echo "================= Localizing ${prodJar} =======================";
rm -f ${prodJar};
echo " HARSHAL : copying ${injectJar} ${prodJar};";
cp -f ${injectJar} ${prodJar};
injectPath=`jar tvf ${injectJar} | grep ${manTop} | awk '{print $NF}'`;
if [[ "$injectPath" = "" ]] then
   errExit " Manipulated topology ${manTop} not found in package ${prodJar}";
   
fi

echo "Injecting manipulated topology to pacakge ${prodJar} under path ${injectPath} ";

chmod 755 ${HOME}/installer/bin/packager/*;
echo "RUNNING INJECTION : ${HOME}/installer/bin/packager/injectPackage.sh -pkg ${HOME}/storage_root/packages/${prodJar} -update ${injectPath} ./${manTop}";
${HOME}/installer/bin/packager/injectPackage.sh -pkg ${HOME}/storage_root/packages/${prodJar} -update ${injectPath} ./${manTop}


#
# Calling script to scp generated topology and inject it to Portoflio9 jar
#
#ant -f /tefnas/tef/tooladm/Scripts/cxpi_prtm.xml -DparentLoc=${parentLoc} -DprodJar=${prodJar} -DmanTop=${manTop}

done
rm -rf ${HOME}/storage_root/packages/deleteme ${HOME}/installer/work;

echo "======================= CXPI Manipulation finished SUCCESSFULLY ====================================";

