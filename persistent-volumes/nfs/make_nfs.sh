# This script setup a simple NFS server for testing
# Tested on Fedora 21
#
#!/bin/bash

if [ ! ${UID} -eq 0 ]; then
    echo "Please switch to root."
    exit 1
fi

# Install packages and start services
yum -y install nfs-utils nfs-utils-lib
systemctl start rpcbind
systemctl start nfs

# Make volume
mkdir /nfs
chown -R nfsnobody:nfsnobody /nfs
chmod 700 -R /nfs

# Make configurations
echo '/nfs *(rw,all_squash)' >> /etc/exports
exportfs -a
