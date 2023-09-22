#!/bin/ksh

sudo /opt/controlm/ctmsrv/ctm_agent/ctm/scripts/shut-ag -u ctmsrv -p ALL -s
sudo /opt/controlm/ctmsrv/ctm_agent/ctm/scripts/start-ag -u ctmsrv -p ALL -s

ssh ctmem@${HOST} "/opt/controlm/ctmem/stop_em.ksh" &
sleep 90
ssh ctmem@${HOST} "/opt/controlm/ctmem/start_em.ksh" &
sleep 120

ssh ctmsrv@${HOST} "/opt/controlm/ctmsrv/stop_ctm.ksh" &
sleep 90
ssh ctmsrv@${HOST} "/opt/controlm/ctmsrv/start_ctm.ksh" &
sleep 120

/opt/controlm/ctmsrv/ctm_agent/ctm/scripts/ag_diag_comm

