curl -O https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/TLSMutualAuthentication/fluentdserver_configmap.yaml
curl -O https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/TLSMutualAuthentication/fluentdserver_deployment.yaml
curl -O https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/TLSMutualAuthentication/fluentd_configmap_patch.yaml

oc create sa fluentdserver
oc adm policy add-scc-to-user  privileged system:serviceaccount:openshift-logging:fluentdserver

PASSPHRASE=oo_passphrase
openssl req -new -x509 -sha256 -days 1095 -newkey rsa:2048 \
              -keyout fluentd.key -out fluentd.crt

oc create secret tls fluentdserver3 --cert=fluentd.cert --key=fluentd.key

oc patch secrets/fluentd --type=json --patch "[{'op':'add','path':'/data/forward_ca_cert','value':'${cat fluentd.cert}'}]" 

sed -i "s/oo_passphrase/${PASSPHRASE}" fluentdserver_configmap.yaml
oc create -f fluentdserver_configmap.yaml
oc create -f fluentdserver_deployment.yaml
oc expose deployment/fluentdserver3
serviceip1=$(oc get service fluentdserver3 -o jsonpath={.spec.clusterIP})

#Add secret and update the configmap
sed -i "s/192.168.1.2/${serviceip1}/" fluentd_configmap_patch.yaml
oc patch configmap/fluentd  --patch "$(cat fluentd_configmap_patch.yaml)"
oc delete fluentd --selector logging-infra=fluentd
