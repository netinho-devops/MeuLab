#!/bin/ksh

. ${HOME}/.profile

echo -e -e "y\ny\n" | /opt/controlm/ctmem/bin/stop_all -U emuser -P Unix12345
