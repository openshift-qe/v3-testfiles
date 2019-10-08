# !/bin/bash
set -e
from_registry=registry-proxy.engineering.redhat.com
to_registry=default-route-openshift-image-registry.apps.qeoanli.qe.devcluster.openshift.com
method=${1:-oc}
cur_dir=$PWD
function syncImage()
{
	from_image=$1
	to_image=$2
        if [[ $method == "docker" ]]; then    
            echo " step 1: docker pull $from_image"
            docker pull $from_image
            echo " step 2: docker tag $from_image $to_image"
            docker tag $from_image $to_image
            echo " step 3: docker push $to_image"
            docker push $to_image
         elif [[ $method == "podman" ]]; then
            echo " step 1: podman pull $from_image"
            podman pull $from_image --tls-verify=false
            echo " step 2: podman tag $from_image $to_image"
            podman tag $from_image $to_image
            echo " step 3: docker push $to_image"
            podman push --cert-dir $Cert_Dir $to_image 
	 else
            echo "# oc image mirror $from_image  $to_image --insecure=true"
            oc image mirror $from_image  $to_image --insecure=true
	fi
}

function syncImages()
{
echo "#sync image from internal regsitry to cluster"
    for image in $(cat ${cur_dir}/OperatorSource_Images_Labels.txt); do
	#Replace with brew if it is internal registry in the csv
	#from_image=image-registry.openshift-image-registry.svc:5000/oepnshift/ose-logging-fluentd:v4.11.123
	#from_image=image-registry.openshift-image-registry.svc:5000/oepnshift/ose-logging-fluentd:v4.11.123-201910110
	#from_image=image-registry.openshift-image-registry.svc:5000/openshift/ose-logging-fluentd@sha256:ffaa7978223c2e5d8b5799437d9d2183631a65a1e25e67517ca7b75b5df07d7b
        #from_image=registry-proxy.engineering.redhat.com/rh-osbs/openshift3-ose-service-catalog@sha256:8e4f255a1f2f376bd337650f26389915d19d3a142241c01f141191385278dacb
	from_image=${image/image-registry.openshift-image-registry.svc:5000\/openshift\//registry-proxy.engineering.redhat.com\/rh-osbs\/openshift-}
	image_labels=$(oc image info $from_image --insecure=true --filter-by-os linux/amd64 -o json |jq '.config.config.Labels')

	if [[ ! $image =~ .*@sha256:.* ]]; then
            #image_name=openshiftx/ose-logging-fluentd:latest
            image_name=${image#*\/}
            #image_name=openshift/ose-logging-fluentd:latest
            image_name=${image_name/*\//openshift\/}
	    to_image_origin_tag=$to_registry/$image_name
	fi

	if [[ "X$image_labels" != "X" ]]; then
            #image_name=openshift/ose-logging-fluentd
	    image_name=$(echo $image_labels |jq -r '.name')
            #image_version=v4.1.0
            image_version=$(echo $image_labels |jq -r '.version')
            #image_release=201905101016
            image_release=$(echo $image_labels |jq -r '.release')

	    to_image_version=$to_registry/$image_name:$image_version
	    to_image_release=$to_registry/$image_name:$image_version-${image_release}
	fi

	if [[ "X$to_image_version"  != "X" ]];then
            syncImage $from_image $to_image_version
        fi

	if [[ "X$to_image_release"  != "X" ]];then
            syncImage $from_image $to_image_release
        fi

	if [[ "X$to_image_origin_tag"  != "X" ]];then
            syncImage $from_image $to_image_origin_tag
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

if [[ $method == "podman" ]]; then
    Cert_Dir=$HOME/.cert.d/${To_Registry}
    mkdir -p $Cert_Dir
    cp ca.crt $Cert_Dir/tls.crt
    podman login "${To_Registry}" -u registry -p `oc sa get-token registry` --cert-dir $Cert_Dir
else
    sudo cp ca.crt /etc/pki/ca-trust/source/anchors/${to_registry}.crt
    sudo update-ca-trust enable
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "#Log in registry"
    echo docker login "${to_registry}" -u registry -p `oc sa get-token registry`
    docker login "${to_registry}" -u registry -p `oc sa get-token registry`
fi

if [[ $? != 0 ]]; then
    echo "Can not login cluster ${to_registry}"
    exit 1
fi

}

###########################Main##########################################
if [[ ! -f ${cur_dir}/OperatorSource_Images_Labels.txt ]]; then
    echo "Couldn't find the file OperatorSourceImage_Labels.txt in current directory, please run getOperatorSourceMetadata.sh to generate it at first"
    exit 1
fi
connectToCluster
syncImages
