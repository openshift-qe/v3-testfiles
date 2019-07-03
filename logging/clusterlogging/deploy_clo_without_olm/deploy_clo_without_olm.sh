#!/bin/bash
registry=${1}
branch=${2:-master}
registry_replace=no
if [[ X"$registry" == X""]]; then
	echo "please specify which registry to used. [brew,stage,prod]"
fi
if [[ X"$registry" == X"brew"]]; then
    registry_url="brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888/openshift/ose-"
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

rm -rf clo; mkdir clo
cd eo
curl -s -O https://raw.githubusercontent.com/anpingli/v3-testfiles/master/logging/clusterlogging/deploy_via_olm/4.2/00_clo_ns.yaml
curl -s -O https://raw.githubusercontent.com/anpingli/v3-testfiles/master/logging/clusterlogging/deploy_via_olm/4.2/00_clo_ns.yaml

if [[ X"$registry_replace" == X"yes"]]; then
sed -i s#quay.io/openshift/origin-#${registry_url}# 05-deployment.yaml

for link in $(ls -1); do
    echo oc create -f $link
done
