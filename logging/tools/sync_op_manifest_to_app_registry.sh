#!/bin/bash
namespace=${1}
if [[ "X$namespace" == "X" ]];then
   echo "please specify the app registry namespace. For example: openshift-operators-stage, aosqe42"
   exit
fi
op_images=${2:-ose-elasticsearch-operator ose-cluster-logging-operator ose-ansible-service-broker-operator ose-template-service-broker-operator}
registry_type=${3:-internal}

version="4.1.$(date +%s)"
declare -A image_registry_dir=( ["ose-elasticsearch-operator"]="elasticsearch-operator" 
	             ["ose-cluster-logging-operator"]="cluster-logging"
	             ["ose-ansible-service-broker-operator"]="openshiftansibleservicebroker"
	             ["ose-template-service-broker-operator"]="openshifttemplateservicebroker")

op_image_list=""

if [ -f "ImageList" ] ;then
	num=$(cat ImageList | wc -l)
	if [[ $num -eq 0 ]];then
            echo "ImageList is blank"
	    exit 1
	fi
else
    echo "No file ImageList in current directory"
    exit 1
fi

for op_image in ${op_images}; do
    image=$(grep $op_image ImageList)
    if [[ "X${image}" == "X" ]]; then
          echo "Warning: ${op_image} is skipped as we couldn't find the Operator images in ImageList"
    else
	if [[ "X${image_registry_dir[$op_image]}" == "X" ]]; then
            echo "Warning: ${op_image} is skipped as we couldn't is repo in predefined varaible image_registry_dir, please ping anli for help"
	else
            echo "Info: ${op_image} manifest will be update"
            op_image_list="${op_image_list} $image"
        fi
    fi 
done

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
    echo ""
    echo "#1) Copy manifest from image"
    for image in $op_image_list; do
    	brew_image=${image/openshift4/openshift}
    	tmp_name=${image/*ose-/ose-}
    	image_name=${tmp_name%:*}
    	repo_name="${image_registry_dir[${image_name}]}"
    	rm -rf $repo_name
        docker pull $brew_image
        ID=$(docker create $brew_image)
        docker cp $ID:/manifests $PWD/${repo_name}
        docker rm $ID
    	echo "# Delete useless files in ${repo_name}"
        find ${repo_name} -name image-references -exec rm {} \;
        find ${repo_name} -name *art.yaml -exec rm {} \;

    	echo "# Manifest for $image_name"
    	ls -1 $PWD/${repo_name}
    done
}

function printImageName()
{
    echo ""
    echo "#2) print Image Names to ${PWD}/CSV_ImageList"
    rm -rf ${PWD}/CSV_ImageList 
    for image in $op_image_list; do
    	tmp_name=${image/*ose-/ose-}
    	image_name=${tmp_name%:*}
    	repo_name="${image_registry_dir[${image_name}]}"
	echo "#The image used in $csv_files"
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
    echo ""
    echo "#3) push manifest to ${namespace}"
    getQuayToken
    for image in $op_image_list; do
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
        operator-courier --verbose push ${repo_name}/  ${namespace} ${repo_name} ${version}  "${Quay_Token}"
    done
}

getManifest
printImageName
pushManifesToRegistry

