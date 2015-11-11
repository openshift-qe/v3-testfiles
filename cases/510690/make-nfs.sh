#!/bin/bash -x

CaseID='510690'

# Run this on your NFS server
# e.g, 10.66.79.133
mkdir --parents /home/data/$CaseID/pv{01,02}

chown -R 1000031001:nfsnobody  /home/data/$CaseID/pv01
chown -R nfsnobody:1000031020  /home/data/$CaseID/pv02

chmod -R 700 /home/data/$CaseID/pv01
chmod -R 770 /home/data/$CaseID/pv02

for PV in pv{01,02}
do
  if ! ( grep -q "/home/data/$CaseID/$PV" /etc/exports )
  then
    echo "/home/data/$CaseID/$PV *(rw,sync)" >> /etc/exports
  fi
done

systemctl start rpcbind
systemctl start nfs-server
exportfs -a
