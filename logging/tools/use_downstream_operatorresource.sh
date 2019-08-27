#!/bin/bash
NAMESPACE=${1:-redhat-operators-art}

function getQuayToken()
{
echo "###get Quay Token"
    if [[ $REFRESH == true || ! -f quay.token ]]; then
        echo -n "Login Quay.io"
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
echo "# disable redhat-operators.yaml"
cat <<EOF >disbale_redhat_operator.yaml
apiVersion: config.openshift.io/v1
kind: OperatorHub
metadata:
  name: cluster
spec:
  disableAllDefaultSources: false
  sources:
  - disabled: true
    name: redhat-operators
EOF
oc apply -f disbale_redhat_operator.yaml

echo "###Create&Update QE OperatorSource"
oc project openshift-marketplace

cat <<EOF >token.yaml
apiVersion: v1
kind: Secret
metadata:
  name: qesecret
  namespace: openshift-marketplace
type: Opaque
stringData:
    token: "${Quay_Token}"
EOF

oc get secret qesecret -o name -n openshift-marketplace
if [[ $? == 0 ]]; then
    oc apply -f token.yaml 
else
    oc create -f token.yaml 
fi

cat <<EOF >OP.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  name: qe-app-registry
  namespace: openshift-marketplace
spec:
  type: appregistry     
  endpoint: https://quay.io/cnr
  registryNamespace: ${NAMESPACE}
  authorizationToken:
    secretName: qesecret
EOF
oc get OperatorSource  qe-app-registry -o name -n openshift-marketplace
if [[ $? == 0 ]];then
    oc apply -f OP.yaml
else
    oc create -f OP.yaml
fi
}

getQuayToken
updateCluster
