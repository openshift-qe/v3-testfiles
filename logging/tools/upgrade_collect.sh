set -x
oc get clusterversion version
oc get co
echo "#1 Maketplace resource"
oc get opsrc -n openshift-marketplace
oc get csc -n openshift-marketplace
oc get pod -n openshift-marketplace

echo "#2 openshift-operators-redhat resource"
oc get og -n openshift-operators-redhat
oc get sub -n openshift-operators-redhat
oc get csv -n openshift-operators-redhat
oc get ip -n openshift-operators-redhat
oc get pod -n openshift-operators-redhat
oc get sa -n openshift-operators-redhat
oc get secret -n openshift-operators-redhat
 
echo "#3 openshift-logging resource"
oc get og -n openshift-logging
oc get sub -n openshift-logging
oc get csv -n openshift-logging
oc get ip -n openshift-logging
oc get pod -n openshift-logging
oc get sa -n openshift-logging
oc get secret -n openshift-logging
oc get oauthclient kibana-proxy
oc get configmap -n openshift-logging
echo "#4 json resource openshift-marketplace"
oc get packagemanifest elasticsearch-operator -n openshift-marketplace -o yaml
oc get packagemanifest cluster-logging -n openshift-marketplace -o yaml
echo "#5 json resource openshift-operators-redhat"
oc get sub -n openshift-operators-redhat -o json
oc get ip -n openshift-operators-redhat  -o json
oc get csv -n openshift-operators-redhat -o json
oc get deloyment -n openshift-operators-redhat -o json
oc get secrect -n openshift-operators-redhat -o json
oc get sa -n openshift-operators-redhat -o json
echo "#6 json resource openshift-logging"
oc get sub -n openshift-logging -o json
oc get ip -n openshift-logging  -o json
oc get csv -n openshift-logging -o json
oc get clusterlogging instance -n openshift-logging -o json
oc get elasticsearch elasticsearch -n openshift-logging -o json
oc get deployment -n openshift-logging -o json
oc get ds -n openshift-logging -o json
oc get cronjob -o json -n openshift-logging
oc get secret -o json -n openshift-logging
oc get sa -o json -n openshift-logging
oc get configmap -o json -n openshift-logging
