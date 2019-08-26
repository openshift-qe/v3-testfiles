# !/bin/bash
set -e
NAMESPACE=${1:-redhat-operators-art}
VERSION=${2}
echo "#############Note! #############"
echo "By default, it will get image list from bundle.yaml"
echo "If no bundle.yaml, and there is only one clusterversion.yaml file, it will try to get image list from it"
echo "If more than one clusterversion.yaml file, it will try to get image list from defaultChannel"
echo "You can specify where to get image list by VERSION"
echo "  getOperatorSourceMetadata.sh  redhat-operators-art 4.1"
echo "#############Note End #############"
echo ""
REPOSITORYS="elasticsearch-operator cluster-logging openshifttemplateservicebroker openshiftansibleservicebroker sriov-network-operator"
#REPOSITORYS="openshifttemplateservicebroker openshiftansibleservicebroker"
#REPOSITORYS="sriov-network-operator"
#REPOSITORYS="elasticsearch-operator cluster-logging"
use_latest=true
work_dir=$PWD

function getQuayToken()
{
    echo "##get Quay Token"
    if [[ "X$REG_QUAY_USER" != "X" && "X$REG_QUAY_PASSWORD" != "X" ]]; then
        USERNAME=$REG_QUAY_USER
        PASSWORD=$REG_QUAY_PASSWORD
    else
        echo "Login Quay.io"
        echo ""
        echo "Quay Username: "
        read USERNAME
        echo "Quay Password: "
        read -s PASSWORD
    fi
    Quay_Token=$(curl -s -H "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d ' { "user": { "username": "'"${USERNAME}"'", "password": "'"${PASSWORD}"'" } }' |jq -r '.token')
    echo "$Quay_Token" > ${work_dir}/quay.token
}

function downloadRepos()
{  
    echo "#Download buldle.yaml from Operator source"
    URL="https://quay.io/cnr/api/v1/packages/${NAMESPACE}/${REPOSITORY}"
    echo "#Get buddle Version"
    curl -s -H "Content-Type: application/json" -H "Authorization: ${Quay_Token}" -XGET $URL |python -m json.tool > manifest.json
    if [[ $use_latest = true ]] ; then
        echo  "#Get latest buddle version"
        release=$(jq -r '.[].release' manifest.json|sort -V |tail -1)
	echo "The version $release will be used "
    else
        releases=$(jq -r '.[].release' manifest.json)
        echo  ""
        echo "Choose buddle version"
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
	echo "The version $release will be used "

    fi
    distget=$(jq -r --arg RELEASE "$release" '.[] | select(.release == $RELEASE).content.digest' manifest.json)
    echo "#Get  buddle_${release}.tar.gz"
    curl -s -H "Content-Type: application/json" -H "Authorization: ${Quay_Token}" -XGET $URL/blobs/sha256/$distget  -o buddle_${release}.tar.gz
    echo "#unzip  buddle_${release}.tar.gz"
    gunzip buddle_${release}.tar.gz
    tar -xvf buddle_${release}.tar
}

function getimageNames()
{
echo "##Get image name from App Registry"


cat <<EOF >getimageNames_buddle.py
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

cat <<EOF >getimageNames_clusterversion.py
'''
Created on July 25, 2019
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
res_ClusterServiceVersion=yaml.load(f, Loader=yaml.FullLoader)
f.close()

for item_deployment in  res_ClusterServiceVersion['spec']['install']['spec']['deployments']:
    for item_container in item_deployment["spec"]["template"]['spec']["containers"]:
        images.append(item_container['image'])
        print str(item_container['image'])
        for  item_env in item_container['env']:
            if(re.search("_IMAGE", item_env['name'])):
                images.append(item_env['value'])
                print item_env['value']
EOF

if [[ "X$VERSION" == "X" ]]; then
    if [[ -f "${PWD}/bundle.yaml" ]] ;then
        echo "#Print Images names"
        echo "python getimageNames_buddle.py -f ${PWD}/bundle.yaml"
        echo "--------"
        python getimageNames_buddle.py -f ${PWD}/bundle.yaml | tee -a ${work_dir}/OperatorSource_Images_Labels.txt
    else
	echo "#Find clusterserviceversion.yaml"
        csv_num=$(find .  -type f -name *clusterserviceversion.yaml  |wc -l)
	clusterserviceversionfile=""
	if [[  "$csv_num" ==  "1" ]]; then
	     echo "#Found one clusterserviceversion.yaml"
             clusterserviceversionfile=$(find ${VERSION} -type f -name *clusterserviceversion.yaml)
             if [[ "X${clusterserviceversionfile}" != "X" ]] ;then
                 echo "#Print Images names"
                 echo "python getimageNames_clusterversion.py -f $clusterserviceversionfile"
                 echo "--------"
                 python getimageNames_clusterversion.py -f $clusterserviceversionfile | tee -a ${work_dir}/OperatorSource_Images_Labels.txt
             fi
        elif [[ "$csv_num" == "0" ]]; then
	     echo "#Found zero clusterserviceversion.yaml"
	else
	     echo "#Found more than one clusterserviceversion.yaml"
	     echo "#Find the defaultChannel in package.yaml"

             pkg_num=$(find . -name  *package.yaml |wc -l)
	     if [[ "$pkg_num" == "1" ]]; then
	         echo "#Found one package.yaml"
		 pkg_file=$(find . -name  *package.yaml)
		 pkg_dir=$(dirname $pkg_file)
		 VERSION=$(grep defaultChannel cluster-logging-ihphqjo6/cluster-logging.package.yaml  |awk '{print $2}' |tr -d '"')
                 clusterserviceversionfile=$(find $pkg_dir/${VERSION} -type f -name *clusterserviceversion.yaml)
                 if [[ "X${clusterserviceversionfile}" != "X" ]] ;then
                     echo "#Print Images names"
                     echo "python getimageNames_clusterversion.py -f $clusterserviceversionfile\n"
                     echo "--------"
                     python getimageNames_clusterversion.py -f $clusterserviceversionfile | tee -a ${work_dir}/OperatorSource_Images_Labels.txt
                 fi
	     fi
        fi
    fi
else
    clusterserviceversionfile=$(find ${VERSION} -type f -name *clusterserviceversion.yaml)
    if [[ "X${clusterserviceversionfile}" != "X" ]] ;then
        echo "#Print Images names"
        echo "python getimageNames_clusterversion.py -f $clusterserviceversionfile\n"
        echo "--------"
        python getimageNames_clusterversion.py -f $clusterserviceversionfile | tee -a ${work_dir}/OperatorSource_Images_Labels.txt
    fi
fi
}

###########################Main##########################################
>${work_dir}/OperatorSource_Images_Labels.txt
getQuayToken
Quay_Token=$(cat ${work_dir}/quay.token)
for REPOSITORY in ${REPOSITORYS}; do
    rm -rf "quay.${REPOSITORY}"
    mkdir -p "quay.${REPOSITORY}"
    cd "quay.${REPOSITORY}"

    echo "##Get Image names for $REPOSITORY"
    downloadRepos
    getimageNames
    cd ${work_dir}
done
