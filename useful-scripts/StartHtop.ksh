#!/usr/bin/env ksh
# Pedro Pavan
# 07-Dec-2016

kernel_version=$(uname -r)
cd ~/Scripts/utils/htop/

for v in $(seq 4 8); do
	current=$(echo "${kernel_version}" | grep -c "el${v}")
	if [ ${current} -eq 1 ]; then
		htop_version="el${v}"
		break
	fi
done

binary="htop.${htop_version}"
./${binary}
