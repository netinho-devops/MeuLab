#!/usr/bin/ksh

#
# Script to compare list of properties of genesis with a generated properties file from topology
#

genLoc=${HOME}/harshal;
srcFile=${HOME}/harshal/AMSSEnvironment.properties;
genFile=${HOME}/harshal/AMSSEnvironment.properties_gen;

srcFilePrefix=`basename ${srcFile}`;
touch ${genLoc}/${srcFilePrefix}_$$;
grep "=" ${srcFile} | grep -v "^#" | grep -v "=if(" | cut -d"=" -f1 | sort >> ${genLoc}/${srcFilePrefix}_$$


genFilePrefix=`basename ${genFile}`;
touch ${genLoc}/${genFilePrefix}_$$;
grep "=" ${genFile} | grep -v "^#" | grep -v "=if(" | cut -d"=" -f1 | sort >> ${genLoc}/${genFilePrefix}_$$

if [[ `diff ${genLoc}/${srcFilePrefix}_$$ ${genLoc}/${genFilePrefix}_$$ | wc -l ` -eq 0 ]] then 
echo "Property names match between Genesis and Generated file";
else 
echo "Property names mis-match between Genesis and Generated file";
exit 1;
fi

rm -f ${genLoc}/*_$$;


