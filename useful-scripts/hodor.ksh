#!/usr/bin/ksh

sed "s|\$(custUsgConnect1:dbservice:xpi.DBServicePhysicalName)|${APP_DB_INST}|g" ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG1TrxDataSource-jdbc.xml > ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG1TrxDataSource-jdbc.xml_HODOR
mv ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG1TrxDataSource-jdbc.xml_HODOR ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG1TrxDataSource-jdbc.xml


sed "s|\$(custUsgConnect2:dbservice:xpi.DBServicePhysicalName)|${APP_DB_INST}|g" ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG2TrxDataSource-jdbc.xml > ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG2TrxDataSource-jdbc.xml_HODOR
mv ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG2TrxDataSource-jdbc.xml_HODOR ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG2TrxDataSource-jdbc.xml


sed "s|\$(custUsgConnect1:xpi.UserName)|${APP_DB_USER}|g" ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG1TrxDataSource-jdbc.xml > ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG1TrxDataSource-jdbc.xml_HODOR
mv ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG1TrxDataSource-jdbc.xml_HODOR ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG1TrxDataSource-jdbc.xml


sed "s|\$(custUsgConnect2:xpi.UserName)|${APP_DB_USER}|g" ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG2TrxDataSource-jdbc.xml > ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG2TrxDataSource-jdbc.xml_HODOR
mv ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG2TrxDataSource-jdbc.xml_HODOR ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG2TrxDataSource-jdbc.xml

target_line=`grep password-encrypted ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ABPRegularDataSource-jdbc.xml`;

sed "s|<password-encrypted.*|COMEATTHEKINGYOUBESTNOTMISS|g" ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG1TrxDataSource-jdbc.xml > ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/HODOR.txt

sed "s|COMEATTHEKINGYOUBESTNOTMISS|${target_line}|g" ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/HODOR.txt > ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG1TrxDataSource-jdbc.xml

rm -f ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/HODOR.txt

sed "s|<password-encrypted.*|COMEATTHEKINGYOUBESTNOTMISS|g" ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG2TrxDataSource-jdbc.xml > ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/HODOR.txt

sed "s|COMEATTHEKINGYOUBESTNOTMISS|${target_line}|g" ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/HODOR.txt > ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/ADJCUSTUSG2TrxDataSource-jdbc.xml

rm -f ${HOME}/JEE/ABPProduct/WLS/ABP-FULL/config/jdbc/HODOR.txt

