#!/bin/bash
namespace=${1:-aosqe42}
registry_type=${2:-quay}
version="4.1.$(date +%s)"

image_list=$(egrep 'ose-elasticsearch-operator|ose-cluster-logging-operator|ose-ansible-service-broker-operator|ose-template-service-broker-operator' ImageList)

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


function getManifest()
{
    echo "#1) Copy manifest from image"
    for image in $image_list; do
    	brew_image=${image/openshift4/openshift}
    	tmp_name=${image/*ose-/ose-}
    	image_name=${tmp_name%:*}
    	repo_name="${image_registry_dir[${image_name}]}"
    	rm -rf $repo_name
        docker pull $brew_image
        ID=$(docker create $brew_image)
        docker cp $ID:/manifests $PWD/${repo_name}
        docker rm $ID
    	echo "# Manifest for $image_name"
    	ls -R1 $PWD/${repo_name}
    done
}

function printImageName()
{
    echo "#2) print Image Names to ${PWD}/CSV_ImageList"
    rm -rf ${PWD}/CSV_ImageList 
    for image in $image_list; do
    	tmp_name=${image/*ose-/ose-}
    	image_name=${tmp_name%:*}
    	repo_name="${image_registry_dir[${image_name}]}"
	echo "#The image used in $$csv_files"
    	csv_files=$(find $repo_name -name *clusterserviceversion.yaml)
    	if [[ $csv_files != "" ]]; then
                cat $csv_files |grep image-registry.openshift-image-registry.svc:5000 |awk '{print $2}' |tr -d '",' |tr -d "'" |sort| uniq | tee -a ${PWD}/CSV_ImageList
                #grep registry.stage.redhat.io  $csv_files |awk '{print $2}' |tr -d '"' |tr -d "'" | tee -a ${PWD}/CSV_ImageList
                #grep registry.redhat.com  $csv_files |awk '{print $2}' |tr -d '"' |tr -d "'" | tee -a ${PWD}/CSV_ImageList
    	fi
    done
}

function pushManifesToRegistry()
{
    getQuayToken
    echo "#3) push manifest to ${namespace}"
    for image in $image_list; do
            tmp_name=${image/*ose-/ose-}
            image_name=${tmp_name%:*}
            repo_name="${image_registry_dir[${image_name}]}"
    	csv_files=$(find $repo_name -name *clusterserviceversion.yaml)
    	if [[ $csv_files != "" ]]; then
                if [[ $registry_type == "quay" ]];then
    		    echo "#Replace image registry to quay"rrr
		    sed -i 's#image-registry.openshift-image-registry.svc:5000/openshift/\(.*\):\(v[^"'\'']*\)#quay.io/openshift-release-dev/ocp-v4.0-art-dev:\1-\2#' $csv_files
                fi
    	fi
        echo "#push manifest ${image_name} to $namespace"
        echo operator-courier --verbose push ${repo_name}/  $namespace ${repo_name} $version  \"$Quay_Token\"
        #operator-courier --verbose push ${repo_name}/  ${namespace} ${repo_name} ${version}  "${Quay_Token}"
    done
}

getManifest
#printImageName
pushManifesToRegistry
