# !/bin/bash
set -e
from_registry=brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888
to_registry=default-route-openshift-image-registry.apps.qeoanli.qe.devcluster.openshift.com
cur_dir=$PWD

function syncImages()
{
echo "#sync image from internal regsitry to cluster"
    for image in $(cat ${cur_dir}/OperatorSourceImage_Labels.txt); do
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
if [[ ! -f ${cur_dir}/OperatorSourceImage_Labels.txt ]]; then
    echo "Couldn't find the file OperatorSourceImage_Labels.txt in current directory, please run getOperatorSourceMetadata.sh to generate it at first"
    exit 1
fi
connectToCluster
syncImages
