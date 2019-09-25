# !/bin/bash
set -e
from_registry=brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888
to_registry=default-route-openshift-image-registry.apps.qeoanli.qe.devcluster.openshift.com
cur_dir=$PWD

function syncImages()
{
echo "#sync image from internal regsitry to cluster"
    for image in $(cat ${cur_dir}/OperatorSource_Images_Labels.txt); do
	#Replace with brew if it is internal registry in the csv
	from_image=${image/image-registry.openshift-image-registry.svc:5000/brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888}
	image_labels=$(oc image info $from_image --insecure=true --filter-by-os linux/amd64 -o json |jq '.config.config.Labels')
        #image_name=openshift/ose-logging-fluentd
	image_name=$(echo $image_labels |jq -r '.name')
	#image_version=v4.1.0
        image_version=$(echo $image_labels |jq -r '.version')
	#image_release=201905101016
        image_release=$(echo $image_labels |jq -r '.release')

	if [[ $image =~ "docker.io" ]]; then
	    echo "skip: this tool doesn't supoprt docker.io"
		continue
	fi

        if [[ $image =~ "quay.io" ]]; then
            echo "skip: this tool doesn't supoprt quay.io"
            continue
            echo " step 1: docker pull $from_image"
            docker pull $from_image
            echo " step 2: docker tag $from_image $to_registry/$image_name:$image_version"
            docker tag $from_image $to_registry/$image_name:$image_version
            echo " step 3: docker push $to_registry/$image_name:$image_version "
            docker push $to_registry/$image_name:$image_version
            echo " step 2: docker tag $from_image $to_registry/$image_name:$image_version-${image_release}"
            docker tag $from_image $to_registry/$image_name:$image_version-${image_release}
            echo " step 3: docker push $to_registry/$image_name:$image_version-${image_release}"
            docker push $to_registry/$image_name:$image_version-${image_release}
        else 
	    echo "# oc image mirror $from_image  $to_registry/$image_name:$image_version --insecure=true"
            oc image mirror $from_image  $to_registry/$image_name:$image_version --insecure=true
            echo "# oc image mirror $from_image  $to_registry/$image_name:$image_version-${image_release} --insecure=true"
            oc image mirror $from_image  $to_registry/$image_name:$image_version-${image_release} --insecure=true
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
