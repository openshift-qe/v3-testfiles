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
 
echo "#3 openshift-logging resource"
oc get og -n openshift-logging
oc get sub -n openshift-logging
oc get csv -n openshift-logging
oc get ip -n openshift-logging
oc get pod -n openshift-logging
echo "#4 Yaml resource"
oc get packagemanifest elasticsearch-operator -n openshift-marketplace -o yaml
oc get packagemanifest cluster-logging -n openshift-marketplace -o yaml
oc get sub -n openshift-operators-redhat -o json
oc get ip -n openshift-operators-redhat  -o json
oc get csv -n openshift-operators-redhat -o json
oc get sub -n openshift-logging -o json
oc get ip -n openshift-logging  -o json
oc get csv -n openshift-logging -o json
oc get clusterlogging instance -o json
oc get elasticsearch elasticsearch -o json
