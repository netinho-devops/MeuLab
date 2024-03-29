#!/bin/ksh

echo "</br>"
echo "</br>"
echo "<div>"

echo "<b><u> ABP URL's:</u> </b>"
echo "<table border='1' > <b>"

echo "<tr bgcolor='4BACC6'> <b>"
echo "<td> <b> Module </b></td>"
echo "<td> <b> URL </b></td>"
echo "</tr>"

export AMC_PORT=`cat ~/Amc-*/config/AmcSystem.properties | grep amc.port | cut -d= -f2`

echo "<tr bgcolor='A5D5E2'>"
echo "<td> AMC </td>"
echo "<td> http://${HOST}:${AMC_PORT} </td>"
echo "</tr>"

echo "<tr bgcolor='D2EAF1' >"
echo "<td> Method Invoker </td>"
echo "<td> http://${HOST}:${UAMS_PORT}/c9att/att/entry.jsp </td>"
echo "</tr>"


echo "<tr bgcolor='A5D5E2'>"
echo "<td> RM </td>"
echo "<td> http://${HOST}:${UAMS_PORT}/rm/controllers/first.jsp?APP_ID=RM </td>"
echo "</tr>"


echo "<tr bgcolor='D2EAF1'>"
echo "<td> AR </td>"
echo "<td> http://${HOST}:${UAMS_PORT}/ar/?APP_ID=AR </td>"
echo "</tr>"


echo "<tr bgcolor='A5D5E2'>"
echo "<td> VM </td>"
echo "<td> http://${HOST}:${UAMS_PORT}/vm/controllers/first.jsp?APP_ID=VM </td>"
echo "</tr>"


echo "<tr bgcolor='D2EAF1'>"
echo "<td> AEM </td>"
echo "<td> https://${HOST}:${ASMM_AEM_HTTP_PORT} </td>"
echo "</tr>"

echo "<tr bgcolor='D2EAF1'>"
echo "<td> OFCA  </td>"
echo "<td> https://${HOST}:${ASMM_CUI_HTTP_PORT} </td>"
echo "</tr>"


echo "</table>"

echo "</div>"
