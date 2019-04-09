oc create sa fluentdserver
oc adm policy add-scc-to-user  privileged system:serviceaccount:openshift-logging:fluentdserver
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/forward/fluentdserver_deployment.yaml
oc expose deployment/fluentdserver1
serviceip1=$(oc get service fluentdserver1 -o jsonpath={.spec.clusterIP})
#Add secret and update the configmap
curl -O https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/forward/fluentd_configmap_patch.yaml
sed -i "s/192.168.1.2/${serviceip1}/" fluentd_configmap_patch.yaml
oc patch configmap/fluentd  --patch "$(cat fluentd_configmap_patch.yaml)"
echo "oc exec $fluentdpod -- cat /fluentd/log/data.log"
