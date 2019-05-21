#!/bin/bash

function getQuayToken()
{
echo "#get Quay Token"
    echo -n "Login Quay.io"
    if [[ $REFRESH == true || ! -f quay.token ]]; then
        echo -n "Quay Username: "
        read USERNAME
        echo -n "Quay Password: "
        read -s PASSWORD

        Quay_Token=$(curl -s -H "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d ' { "user": { "username": "'"${USERNAME}"'", "password": "'"${PASSWORD}"'" } }' |jq -r '.token')
        echo "$Quay_Token" > quay.token
    else
        Quay_Token=$(cat quay.token)
    fi

}

function updateCluster()
{
#echo "#set OperatorSource unmanaged"
cat <<EOF > above.yaml
apiVersion: config.openshift.io/v1
kind: ClusterVersion
metadata:
  name: version
spec:
  overrides:
    - kind: OperatorSource
      name: certified-operators
      namespace: openshift-marketplace
      unmanaged: true
    - kind: OperatorSource
      name: redhat-operators
      namespace: openshift-marketplace
      unmanaged: true
    - kind: OperatorSource
      name: community-operators
      namespace: openshift-marketplace
      unmanaged: true
EOF
#oc apply -f above.yaml

echo "#Delete offical OperatorSource"
oc project openshift-marketplace
#oc delete opsrc redhat-operators  |  true
#oc delete opsrc certified-operators | true
#oc delete opsrc community-operators | true

echo "#Create Art OperatorSource"

cat <<EOF >token.yaml
apiVersion: v1
kind: Secret
metadata:
  name: marketplacesecret
  namespace: openshift-marketplace
type: Opaque
stringData:
    token: "${Quay_Token}"
EOF
oc create -f token.yaml 


cat <<EOF >OP.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  name: art-applications
  namespace: openshift-marketplace
spec:
  type: appregistry     
  endpoint: https://quay.io/cnr
  registryNamespace: redhat-operators-art
  authorizationToken:
    secretName: marketplacesecret
EOF
oc create -f OP.yaml
}

getQuayToken
updateCluster
