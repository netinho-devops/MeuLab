!/bin/ksh -xv

for i in illin1391 illin1393 illin1084 illin1577 illin1576 illin1336 illin1396 illin1397 illin1579 illin1394 illin1580 illin1581 illin1805 illin2115 illin2116 illin2109 illin2120 ilvpbg165 ilmtx1001; do
echo "copy file to $i"
scp ~/Scripts/vf.gf.dmn-serial-numbers.txt  tooladm@$i:/etc/opt/vmware/vfabric/
done 
