#!/usr/bin/env bash
#test description: to add google idp

set -o errexit
set -o nounset
set -o pipefail

echo -e "\033[44;37mPlease execute this script on the machine which contains kubeconfig file!\033[0m"
echo -n "please enter the kubeconfig absolute path ->"
read KC

datename=$(date +%Y%m%d-%H%M%S)

step(){
echo -e "\033[47;30m$1\033[0m"
}

checkreturn(){
if [ $? -ne 0 ]; then
echo -e "`date +%H:%M:%S` \033[31mThe step failed and you need to get the cluster status back manually e.g switch back to previous user!!! \033[0m"
exit 1
fi
}

if [ ! -f ${KC} ];then
echo -e "`date +%H:%M:%S` \033[31mThe kubeconfig file doesn't exit \033[0m"
exit 1
fi

step "Step 1: check whether oc client exits"
which "oc" > /dev/null
if [ $? -eq 0 ]
then
echo -e "`date +%H:%M:%S` \033[32m oc command is exist \033[0m"
else
echo -e "`date +%H:%M:%S` \033[31m oc command not exist,you should install the oc client on master \033[0m"
exit 1
fi

step "Step 2: switch to cluster-admin user"
CC=`oc config current-context --config="${KC}"`
oc login -u system:admin --config="${KC}" > /dev/null
checkreturn


step "Step 3: please input the client ID and secrete from google:"
echo Please enter your clientId
read clientId
echo Please enter your secret
read secret
echo "oc create secret generic google-secret --from-literal=clientSecret=$secret -n openshift-config"
echo "clientID is $clientId"

OUT=./oauth_google.yaml

oc get oauth cluster -o yaml > $OUT
cat <<EOF >> $OUT
  - google:
      clientID: $clientId
      clientSecret:
        name: google-secret
      hostedDomain: redhat.com
    mappingMethod: claim
    name: googleidp
    type: Google
EOF

cat $OUT
sleep 1
oc apply -f $OUT
sleep 1
oc create secret generic google-secret --from-literal=clientSecret=$secret -n openshift-config

sleep 30


step "Step 4: switch back to previous user"
oc config use-context ${CC} --config="${KC}"
checkreturn

echo -e "\033[32mAll Success\033[0m"
