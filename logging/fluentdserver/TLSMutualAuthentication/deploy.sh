oc create sa fluentdserver
oc adm policy add-scc-to-user  privileged system:serviceaccount:openshift-logging:fluentdserver
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/TLSMutualAuthentication/fluentdserver_configmap.yaml
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/TLSMutualAuthentication/fluentdserver_deployment.yaml
oc expose deployment/fluentdserver3
serviceip1=$(oc get service fluentdserver3 -o jsonpath={.spec.clusterIP})
#Add secret and update the configmap
curl -O https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/TLSMutualAuthentication/fluentd_configmap_patch.yaml
sed -i "s/192.168.1.2/${serviceip1}/" fluentd_configmap_patch.yaml
oc patch configmap/fluentd  --patch "$(cat fluentd_configmap_patch.yaml)"
