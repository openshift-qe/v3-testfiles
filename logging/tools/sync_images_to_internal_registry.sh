# !/bin/bash
set -e
NAMESPACE=redhat-operators-art
REPOSITORYS="elasticsearch-operator cluster-logging"
#REPOSITORYS="metering  openshifttemplateservicebroker  openshiftansibleservicebroker"
REFRESH=true
from_registry=brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888
to_registry=default-route-openshift-image-registry.apps.qeoanli.qe.devcluster.openshift.com
cur_dir=$PWD

function getQuayToken()
{
echo "#get Quay Token"
    echo "Login Quay.io"
    echo ""
    echo "Quay Username: "
    read USERNAME
    echo "Quay Password: "
    read -s PASSWORD
 
    Quay_Token=$(curl -s -H "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d ' { "user": { "username": "'"anli"'", "password": "'"beginr00t"'" } }' |jq -r '.token')
    echo "$Quay_Token" > ${cur_dir}/quay.token
}

function downloadRepos()
{  
echo "#Download buldle.yaml from Operator source"
    Quay_Token=$(cat ${cur_dir}/quay.token)
    rm -rf "quay.${REPOSITORY}"
    mkdir -p "quay.${REPOSITORY}"
    cd "quay.${REPOSITORY}"
    URL="https://quay.io/cnr/api/v1/packages/${NAMESPACE}/${REPOSITORY}"
    echo curl -s -H "Content-Type: application/json" -H "Authorization: ${Quay_Token}" -XGET $URL 
    curl -s -H "Content-Type: application/json" -H "Authorization: ${Quay_Token}" -XGET $URL |python -m json.tool > manifest.json
    releases=$(jq -r '.[].release' manifest.json)
    echo  ""
    echo "##Download repos for $REPOSITORY"
    echo  ""
    jq '.[].release ' manifest.json |tr  ["\n"] ' '
    echo  ""
    echo "Please input one version to download"
    echo  ""
    read -s release
    match=false
    for version in ${releases}; do
        if [[ $release == $version ]];then
            match=true
	fi
    done
    if [[ $match == flase ]]; then
        echo "you must use version in the list"
	exit 1
    fi
    distget=$(jq -r --arg RELEASE "$release" '.[] | select(.release == $RELEASE).content.digest' manifest.json)
    curl -s -H "Content-Type: application/json" -H "Authorization: ${Quay_Token}" -XGET $URL/blobs/sha256/$distget  -o buddle_${release}.tar.gz
    gunzip buddle_${release}.tar.gz
    tar -xvf buddle_${release}.tar
    cd ..
}

function getimageNames()
{
echo "#Get image name from Operator source"
cat <<EOF >getimageNames.py
'''
Created on May 9, 2019
@author: anli@redhat.com
'''
import argparse
import re
import sys
import os
import yaml

images=[]
parser = argparse.ArgumentParser()
parser.add_argument('-f', '--file')
args=parser.parse_args()

"""
pip install pyyaml
http://ansible-tran.readthedocs.io/en/latest/docs/YAMLSyntax.html
"""
f = open(args.file)
res=yaml.load(f, Loader=yaml.FullLoader)
f.close()
#print(res)
res2=yaml.load(res['data']['clusterServiceVersions'],Loader=yaml.FullLoader)
#print res2
for vitem in res2:
    for ditem in  vitem['spec']['install']['spec']['deployments']:
        for citem in ditem["spec"]["template"]['spec']["containers"]:
            images.append(citem['image'])
            print str(citem['image'])
            for  eitem in citem['env']:
                if(re.search("_IMAGE", eitem['name'])):
                    images.append(eitem['value'])
                    print eitem['value']
EOF
    python getimageNames.py -f quay.${REPOSITORY}/bundle.yaml | tee -a ${cur_dir}/quay.images
}

function syncImages()
{
echo "#sync image from internal regsitry to cluster"
    for image in $(cat ${cur_dir}/quay.images); do
        echo $image
        if [[ $image =~ image-registry.openshift-image-registry.svc:5000 ]]; then
            #openshift/ose-logging-fluentd:v4.1.0-201905101016
            image_name=${image#*image-registry.openshift-image-registry.svc:5000\/} 
            #openshift/ose-logging-fluentd
            image_rawname=${image_name%%:*} 
            #v4.1.0-201905101016
            image_tag=${image##*:}
            #v4.1.0 
            image_version=${image_tag%-*}
            echo " Sync image $image"    
            echo "----------------------------"
            echo " step 1: docker pull $from_registry/${image_name} "
            docker pull $from_registry/${image_name}
            echo " step 2: docker tag $from_registry/${image_name}  $to_registry/${image_name}"
            docker tag $from_registry/${image_name}  $to_registry/${image_name}
            echo " step 3: docker push $to_registry/${image_name} "
            docker push $to_registry/${image_name}
            echo " step 4: docker tag $from_registry/${image_name}  $to_registry/${image_rawname}:${image_tag}"
            docker tag $from_registry/${image_name}  $to_registry/${image_rawname}:${image_tag}
            echo " step 5: $to_registry/${image_rawname}:${image_tag}"
            docker push  $to_registry/${image_rawname}:${image_tag}
        fi
    done
}

function connectToCluster()
{
echo "#Enable external router for regsitry"
cat <<EOF >/tmp/defaultRoute.yaml
apiVersion: imageregistry.operator.openshift.io/v1
kind: Config
metadata:
  name: cluster
spec:
  defaultRoute: true
EOF
oc apply -f /tmp/defaultRoute.yaml
echo "#Configure cert and token to registry"
to_registry=$(oc get images.config.openshift.io/cluster  -o jsonpath={.status.externalRegistryHostnames[0]})
oc create serviceaccount registry |true
oc adm policy add-cluster-role-to-user admin -z registry
oc get secret router-certs-default -n openshift-ingress -o json |jq -r '.data["tls.crt"]' | base64 -d >ca.crt
sudo cp ca.crt /etc/pki/ca-trust/source/anchors/${to_registry}.crt
sudo update-ca-trust enable
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "#Log in registry"
echo docker login "${to_registry}" -u registry -p `oc sa get-token registry`
docker login "${to_registry}" -u registry -p `oc sa get-token registry`
if [[ $? != 0 ]]; then
    echo "Can not login cluster ${to_registry}"
    exit 1
fi
}

###########################Main##########################################
getQuayToken
if [[ $REFRESH == true ]]; then
    >${cur_dir}/quay.images
    for REPOSITORY in ${REPOSITORYS}; do
        echo "#get Image names for $REPOSITORY"
        downloadRepos
        getimageNames
    done
fi
connectToCluster
syncImages
