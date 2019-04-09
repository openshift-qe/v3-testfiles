oc create sa fluentdserver
oc adm policy add-scc-to-user  privileged system:serviceaccount:openshift-logging:fluentdserver
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/TLSMutualAuthentication/fluentdserver_configmap.yaml
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/TLSMutualAuthentication/fluentdserver_deployment.yaml
oc expose deployment/fluentdserver
serviceip1=$(oc get service fluentdserver -o jsonpath={.spec.clusterIP})
oc scale deployment cluster-logging-operator --replicas=0
#Add secret and update the configmap
curl -O https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/fluentdserver/TLSMutualAuthentication/fluentd_configmap_patch.yaml
sed -i "s/192.168.1.2/${serviceip1}/" fluentd_configmap_patch.yaml
oc patch configmap/fluentd  --patch "$(cat fluentd_configmap_patch.yaml)"
