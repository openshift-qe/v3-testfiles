# !/bin/bash
set -e
NAMESPACE=redhat-operators-art
REPOSITORYS="elasticsearch-operator cluster-logging metering openshifttemplateservicebroker openshiftansibleservicebroker"
REFRESH=true
use_latest=true
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
 
    Quay_Token=$(curl -s -H "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d ' { "user": { "username": "'"${USERNAME}"'", "password": "'"${PASSWORD}"'" } }' |jq -r '.token')
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
    if [[ $use_latest = true ]] ; then
        release=$(jq -r '.[].release' manifest.json|sort -V |tail -1)
	echo "The version $release will be used "
    else
        releases=$(jq -r '.[].release' manifest.json)
        echo  ""
        echo "##Download repos for $REPOSITORY"
        echo  ""
        jq '.[].release ' manifest.json |tr  ["\n"] ' '
        echo  ""
        echo "Please input one version to download"
        echo  ""
        read release
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
	echo "The version $release will be used "

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
    python getimageNames.py -f quay.${REPOSITORY}/bundle.yaml | tee -a ${cur_dir}/OperatorSourceImage_Labels.txt
}


###########################Main##########################################
getQuayToken
>${cur_dir}/OperatorSourceImage_Labels.txt

for REPOSITORY in ${REPOSITORYS}; do
    echo "#get Image names for $REPOSITORY"
    downloadRepos
    getimageNames
done
