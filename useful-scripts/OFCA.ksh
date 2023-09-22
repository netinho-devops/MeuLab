#!/usr/bin/env ksh
# Pedro Pavan
# Used on BM - should be improved

stop() {
${ASMM_INSTALL_PATH}Core/bin/xacct disable > /dev/null 2>&1
${ASMM_INSTALL_PATH}G1_PROCESSING1/bin/xacct disable > /dev/null 2>&1
${ASMM_INSTALL_PATH}G2_PROCESSING2/bin/xacct disable > /dev/null 2>&1
${ASMM_INSTALL_PATH}G3_PROCESSING3/bin/xacct disable > /dev/null 2>&1
${ASMM_INSTALL_PATH}G4_PROCESSING4/bin/xacct disable > /dev/null 2>&1
}

start() {
${ASMM_INSTALL_PATH}Core/bin/xacct enable > /dev/null 2>&1
${ASMM_INSTALL_PATH}G1_PROCESSING1/bin/xacct enable > /dev/null 2>&1
${ASMM_INSTALL_PATH}G2_PROCESSING2/bin/xacct enable > /dev/null 2>&1
${ASMM_INSTALL_PATH}G3_PROCESSING3/bin/xacct enable > /dev/null 2>&1
${ASMM_INSTALL_PATH}G4_PROCESSING4/bin/xacct enable > /dev/null 2>&1
}

status() {
${ASMM_INSTALL_PATH}Core/bin/xacct test
${ASMM_INSTALL_PATH}G1_PROCESSING1/bin/xacct test
${ASMM_INSTALL_PATH}G2_PROCESSING2/bin/xacct test
${ASMM_INSTALL_PATH}G3_PROCESSING3/bin/xacct test
${ASMM_INSTALL_PATH}G4_PROCESSING4/bin/xacct test
}

ping() {
_result=$(status 2> /dev/null | grep -c OK)

if [ ${_result} -eq 6 ]; then
	echo UP
	return 0
else
	echo DOWN
	return 1
fi
}

$1 2> /dev/null
return $?
