# Configure cli
#
#!/bin/bash

if [ ! $# -eq 3 ]; then
    echo 'Must provide master hostname/ip, username and password'
    exit 1
fi

master=$1
user=$2
password=$3
ca_dir=$HOME
sshopts="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

echo 'Creating user'
ssh $sshopts root@$master <<EOF
htpasswd -b /etc/origin/openshift-passwd $user $password
oadm new-project $user
oadm policy add-role-to-user admin $user
oadm policy add-cluster-role-to-user cluster-admin $user
EOF

echo 'Copying ca cert'
scp $sshopts root@$master:/etc/origin/master/ca.crt ~/

rm -f ~/.config/openshift/config
oc login $master:8443 --certificate-authority=$ca_dir/ca.crt -u $user -p $password

# Switch to the project
oc project $user
