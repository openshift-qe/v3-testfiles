# !/bin/bash
set -e
from_registry=brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888
to_registry=default-route-openshift-image-registry.apps.qeoanli.qe.devcluster.openshift.com
cur_dir=$PWD

function syncImages()
{
echo "#sync image from internal regsitry to cluster"
    for image in $(cat ${cur_dir}/OperatorSource_Images_Labels.txt); do
        echo $image
        if [[ $image =~ image-registry.openshift-image-registry.svc:5000 ]]; then
                #image_tag:openshift/ose-logging-fluentd:v4.1.0-201905101016
                image_tag=${image#*image-registry.openshift-image-registry.svc:5000\/} 
		image_labels=$(oc image info $from_registry/${image_tag} --insecure=true --filter-by-os linux/amd64 -o json |jq '.config.config.Labels')
                #image_name=openshift/ose-logging-fluentd
		image_name=$(echo $image_labels |jq -r '.name')
		#image_version=v4.1.0
                image_version=$(echo $image_labels |jq -r '.version')
		#image_release=201905101016
                image_release=$(echo $image_labels |jq -r '.release')

                echo " Sync image $image_tag to internal registry"    
		echo "================================="
	        oc image mirror $from_registry/${image_tag}  $to_registry/${image_name}:$image_version --insecure=true
		oc image mirror $from_registry/${image_tag}  $to_registry/${image_name}:$image_version-${image_release} --insecure=true
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
#oc get secret router-certs-default -n openshift-ingress -o json |jq -r '.data["tls.crt"]' | base64 -d >ca.crt
#sudo cp ca.crt /etc/pki/ca-trust/source/anchors/${to_registry}.crt
#sudo update-ca-trust enable
#sudo systemctl daemon-reload
#sudo systemctl restart docker

echo "#Log in registry"
echo docker login "${to_registry}" -u registry -p `oc sa get-token registry`
docker login "${to_registry}" -u registry -p `oc sa get-token registry`
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
