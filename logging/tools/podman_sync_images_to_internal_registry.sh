# !/bin/bash
set -e
From_Registry=brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888
To_Registry=default-route-openshift-image-registry.apps.qeoanli.qe.devcluster.openshift.com
Cert_Dir=$HOME/cert.d
Cur_Dir=$PWD

function syncImages()
{
echo "#sync image from internal regsitry to cluster"
    for image in $(cat ${Cur_Dir}/OperatorSource_Images_Labels.txt); do
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
            echo " step 1: podman pull $From_Registry/${image_name} "
            podman pull $From_Registry/${image_name} --tls-verify=false
            echo " step 2: podman tag $From_Registry/${image_name}  $To_Registry/${image_name}"
            podman tag $From_Registry/${image_name}  $To_Registry/${image_name}
            echo " step 3: podman push $To_Registry/${image_name} "
            podman push --cert-dir $Cert_Dir $To_Registry/${image_name}
            echo " step 4: podman tag $From_Registry/${image_name}  $To_Registry/${image_rawname}:${image_tag}"
            podman tag $From_Registry/${image_name}  $To_Registry/${image_rawname}:${image_tag}
            echo " step 5: $To_Registry/${image_rawname}:${image_tag}"
            podman push --cert-dir $Cert_Dir $To_Registry/${image_rawname}:${image_tag}
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
To_Registry=$(oc get images.config.openshift.io/cluster  -o jsonpath={.status.externalRegistryHostnames[0]})
Cert_Dir=$HOME/.cert.d/${To_Registry}
mkdir -p $Cert_Dir
oc create serviceaccount registry |true
oc adm policy add-cluster-role-to-user admin -z registry
oc get secret router-certs-default -n openshift-ingress -o json |jq -r '.data["tls.crt"]' | base64 -d >$Cert_Dir/tls.crt

echo "#Log in registry"
echo podman login "${To_Registry}" -u registry -p `oc sa get-token registry`
podman login "${To_Registry}" -u registry -p `oc sa get-token registry` --cert-dir $Cert_Dir
if [[ $? != 0 ]]; then
    echo "Can not login cluster ${To_Registry}"
    exit 1
fi
}

###########################Main##########################################
if [[ ! -f ${Cur_Dir}/OperatorSource_Images_Labels.txt ]]; then
    echo "Couldn't find the file OperatorSourceImage_Labels.txt in current directory, please run getOperatorSourceMetadata.sh to generate it at first"
    exit 1
fi
connectToCluster
syncImages
