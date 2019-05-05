oc create sa rsyslogserver
oc adm policy add-scc-to-user privileged system:serviceaccount:openshift-logging:rsyslogserver
oc create -f rsyslogserver.yaml
oc expose dc rsyslogserver
serviceip1=`oc get service rsyslogserver custom-columns=IP:.spec.clusterIP`
oc scale deployment cluster-logging-operator --replicas=0
oc set env ds/fluentd USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=${serviceip1}  REMOTE_SYSLOG_TAG_KEY='ident,systemd.u.SYSLOG_IDENTIFIER'  REMOTE_SYSLOG_USE_RECORD=true REMOTE_SYSLOG_SEVERITY=info
