#!/usr/bin/ksh 
 #sshpass -p 'Unix11!' ssh abpwkr1@illinqw201 2>/dev/null

while [[ 1 -eq 1 ]];do
# sshpass -p Unix11! ssh -o StrictHostKeyChecking=no abpwkr1@illinqw201 2>/dev/null
 #ssh abpwrk1@illinqw201
 	if [[ -f /users/gen/abpwrk1/storage_root/packages/PCI1-xdk-general-9.1.0.0.0654.jar ]]
		then
		mv /users/gen/abpwrk1/storage_root/packages/PCI1-xdk-general-9.1.0.0.0654.jar /users/gen/abpwrk1/storage_root/packages/PCI1-xdk-general-9.1.0.0.0654.jar_orig
	fi
done	
	