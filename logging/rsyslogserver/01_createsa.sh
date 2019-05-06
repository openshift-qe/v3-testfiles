oc project openshift-logging
oc create sa rsyslogserver
oc adm policy add-scc-to-user privileged system:serviceaccount:openshift-logging:rsyslogserver
