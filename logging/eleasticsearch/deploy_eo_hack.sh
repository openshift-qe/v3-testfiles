#!/bin/bash
registry=${1}
branch=${2:-master}
registry_replace=no
if [[ X"$registry" == X""]]; then
	echo "please specify which registry to used. [brew,stage,prod]"
fi
if [[ X"$registry" == X"brew"]]; then
    registry_url="registry.example.com/openshift/ose-"
    registry_replace=yes
fi

if [[ X"$registry" == X"stage"]]; then
    registry_url="registry.stage.redhat.io/openshif4/ose-"
    registry_replace=yes
fi

if [[ X"$registry" == X"prod"]]; then
    registry_url="registry.redhat.io/openshift3/ose-"
    registry_replace=yes
fi

rm -rf eo; mkdir eo
cd eo
curl -s -O https://raw.githubusercontent.com/anpingli/v3-testfiles/master/logging/eleasticsearch/deploy_via_olm/4.2/01_eo-project.yaml
curl -s -O https://raw.githubusercontent.com/openshift/elasticsearch-operator/${branch}/manifests/01-service-account.yaml
curl -s -O https://raw.githubusercontent.com/openshift/elasticsearch-operator/${branch}/manifests/02-role.yaml	
curl -s -O https://raw.githubusercontent.com/openshift/elasticsearch-operator/${branch}/manifests/03-role-bindings.yaml
curl -s -O https://raw.githubusercontent.com/openshift/elasticsearch-operator/${branch}/manifests/04-crd.yaml
curl -s -O https://raw.githubusercontent.com/openshift/elasticsearch-operator/${branch}/manifests/05-deployment.yaml

if [[ X"$registry_replace" == X"yes"]]; then
sed -i s#quay.io/openshift/origin-#${registry_url}# 05-deployment.yaml

for link in $(ls -1); do
    echo oc create -f $link
done
