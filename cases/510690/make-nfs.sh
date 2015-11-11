#!/bin/bash -x

CaseID='510690'

if ! ( rpm -qa | grep -q nfs-utils )
then
  yum install -y nfs-utils
fi

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

if ( getsebool virt_use_nfs | grep -q off )
then
  setsebool -P virt_use_nfs 1
fi
