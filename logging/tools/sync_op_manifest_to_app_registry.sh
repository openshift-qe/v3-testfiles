#!/bin/bash
namespace=${1:-aosqe42}
version="4.1.$(date +%s)"
image_list=$(egrep 'ose-elasticsearch-operator|ose-cluster-logging-operator|ose-ansible-service-broker-operator|ose-template-service-broker-operator' ImageList)
#ImageList is the file with image url line by line. For example:
#registry.example.com/openshift/ose-elasticsearch-operator:v4.2



declare -A image_registry_dir=( ["ose-elasticsearch-operator"]="elasticsearch-operator" 
	             ["ose-cluster-logging-operator"]="cluster-logging"
	             ["ose-ansible-service-broker-operator"]="openshiftansibleservicebroker"
	             ["ose-template-service-broker-operator"]="openshifttemplateservicebroker")


function getQuayToken()
{
    if [[ -e ${PWD}/quay.token ]]; then
	    Quay_Token=$(cat ${PWD}/quay.token)
    else 
        echo "##get Quay Token"
        if [[ "X$REG_QUAY_USER" != "X" && "X$REG_QUAY_PASSWORD" != "X" ]]; then
            USERNAME=$REG_QUAY_USER
            PASSWORD=$REG_QUAY_PASSWORD
        else
            USERNAME="anli"
            PASSWORD="aosqe2019"
        fi
        Quay_Token=$(curl -s -H "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d ' { "user": { "username": "'"${USERNAME}"'", "password": "'"${PASSWORD}"'" } }' |jq -r '.token')
        echo "$Quay_Token" > ${PWD}/quay.token
    fi
}


getQuayToken
for image in $image_list; do
	brew_image=${image/openshift4/openshift}
	tmp_name=${image/*ose-/ose-}
	image_name=${tmp_name%:*}
	repo_name="${image_registry_dir[${image_name}]}"
	echo "## copy manifest from image $image"
        ID=$(docker create $brew_image)
        docker cp $ID:/manifests $PWD/${repo_name}
        docker rm $ID
	echo "## push csv to $app_registry"
        echo operator-courier --verbose push ${repo_name}/  $namespace ${repo_name} $version  \"$Quay_Token\"
        operator-courier --verbose push ${repo_name}/  ${namespace} ${repo_name} ${version}  "${Quay_Token}"
done
