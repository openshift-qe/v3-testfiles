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
echo "###set OperatorSource unmanaged"
cat <<EOF > clusterversion.yaml
apiVersion: config.openshift.io/v1
kind: ClusterVersion
metadata:
  name: version
spec:
  overrides:
    - kind: OperatorSource
      name: redhat-operators
      namespace: openshift-marketplace
      unmanaged: true
EOF
oc apply -f clusterversion.yaml

oc project openshift-marketplace

echo "###Create&Update QE OperatorSource"

cat <<EOF >qesecret.yaml
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
    oc apply -f qesecret.yaml 
else
    oc create -f qesecret.yaml 
fi

cat <<EOF >OP.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  labels:
    opsrc-provider: redhat
  name: redhat-operators
  namespace: openshift-marketplace
spec:
  authorizationToken:
    secretName: qesecret
  displayName: Red Hat Operators
  endpoint: https://quay.io/cnr
  publisher: Red Hat
  registryNamespace: ${NAMESPACE}
  type: appregistry
EOF
oc get OperatorSource redhat-operators -o name -n openshift-marketplace
if [[ $? == 0 ]];then
    oc apply -f OP.yaml
else
    oc create -f OP.yaml
fi
}

getQuayToken
updateCluster
