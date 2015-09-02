#!/bin/bash

if [ $# -eq 0 ]; then
    echo 'Please provide mininon hostname or ip'
    exit 1
fi

minion=$1
sshopts="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

ssh $sshopts root@$minion <<EOF
yum install nfs-utils glusterfs glusterfs-fuse attr iscsi-initiator-utils -y
echo '10.66.79.155 nfs-server' >> /etc/hosts
echo '10.66.79.108 glusterfs-node01' >> /etc/hosts
echo '10.66.79.154 glusterfs-node02' >> /etc/hosts
EOF
