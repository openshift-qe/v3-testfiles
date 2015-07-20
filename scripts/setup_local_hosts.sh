# Configure /etc/hosts
#!/bin/bash

if [ ! $# -eq 1 ]; then
    echo 'A master server hostname or ip must be provided'
    exit 1
fi

master=$1
tmpfile=/tmp/hosts
sshopts="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

scp $sshopts root@$master:/etc/hosts $tmpfile

# Backup current /etc/hosts
cp /etc/hosts /tmp/hosts_bak

# Update /etc/hosts
sudo sed -i "/\.cluster\.local/d" /etc/hosts
sudo sh -c "grep 'cluster.local' $tmpfile >> /etc/hosts"
