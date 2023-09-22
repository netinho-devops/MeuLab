#!/bin/ksh

sudo /opt/controlm/ctmsrv/ctm_agent/ctm/scripts/shut-ag -u ctmsrv -p ALL -s
sudo /opt/controlm/ctmsrv/ctm_agent/ctm/scripts/start-ag -u ctmsrv -p ALL -s

