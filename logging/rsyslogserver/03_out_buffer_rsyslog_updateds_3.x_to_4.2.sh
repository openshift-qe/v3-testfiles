#! /bin/bash
# Enable fluentd to send log to remote rsyslog server using out_rsyslog_buffer. out_rsyslog_buffer send message via TCP.
oc project openshift-logging
kubeversion=$(oc version -o json | jq '.serverVersion.minor')
kubeversion=${kubeversion:1:2}

fluentds="fluentd"

if [[ $kubeversion < 13 ]] ; then
        echo "v3.x: The fluent ds name is logging-fluentd"
	fluentds=logging-fluentd
else
        echo "v4.x+: The fluent ds name is fluentd"
fi

declare -a RsyslogServiceNames

#RsyslogServiceNames=$(oc get service -l component=rsyslogserver -o jsonpath={.items[*].spec.clusterIP})
RsyslogServiceNames=$(oc get service -l component=rsyslogserver -o json |jq -r '.items[].metadata.name + ".openshift-logging.svc.cluster.local"')

echo 'apiVersion: logging.openshift.io/v1
kind: ClusterLogging
metadata:
  name: instance
  namespace: openshift-logging
spec:
  managementState: Unmanaged' | oc apply -f -

if [[ ${#RsyslogServiceNames[@]} == 0 ]]; then 
   echo "No rsyslog server can be found !"
   exit 1
fi
if [[ ${#RsyslogServiceNames[@]} > 0 ]]; then 
   echo "use ${RsyslogServiceNames[0]} as REMOTE_SYSLOG_HOST"
   oc set env ds/${fluentds} USE_REMOTE_SYSLOG=true REMOTE_SYSLOG_HOST=${RsyslogServiceNames[0]}  REMOTE_SYSLOG_TAG_KEY='ident,systemd.u.SYSLOG_IDENTIFIER'  REMOTE_SYSLOG_USE_RECORD=true REMOTE_SYSLOG_SEVERITY=info REMOTE_SYSLOG_TYPE=syslog_buffered 
fi
if [[ ${#RsyslogServiceNames[@]} > 1 ]]; then 
   echo "use ${RsyslogServiceNames[1]} as REMOTE_SYSLOG_HOST_BACKUP"
   oc set env ds/${fluentds} USE_REMOTE_SYSLOG_BACKUP=true REMOTE_SYSLOG_HOST_BACKUP=${RsyslogServiceNames[1]}  REMOTE_SYSLOG_TAG_KEY_BACKUP='ident,systemd.u.SYSLOG_IDENTIFIER'  REMOTE_SYSLOG_USE_RECORD_BACKUP=true REMOTE_SYSLOG_SEVERITY_BACKUP=info
fi

