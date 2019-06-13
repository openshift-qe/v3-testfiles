#! /bin/bash
# Send log to rsyslog server using out_rsyslog. out_rsyslog send message via UDP
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

# Get all rsyslog server IP
rsyslogservers=$(oc get service -l component=rsyslogserver -o jsonpath={.items[*].spec.clusterIP})
declare -a serviceIPs
serviceIPs=($(echo $rsyslogservers))
if [[ ${#serviceIPs[@]} == 0 ]]; then 
   echo "No rsyslog server can be found !"
   exit 1
fi

#patch the fluentd configmap
cat<< EOF >${fluentds}_cm_patch.yaml
apiVersion: v1
data:
  output-extra-rsyslog.conf: |
    <store>
      @type syslog
      @id remote-syslog-input
      remote_syslog ${serviceIPs[0]}
      port 514
      hostname \${hostname}
      tag_key ident,systemd.u.SYSLOG_IDENTIFIER
      facility local0
      severity info
      use_record true
    </store>

kind: ConfigMap
metadata:
  name: ${fluentds}
  namespace: openshift-logging
EOF

oc apply -f ${fluentds}_cm_patch.yaml

# Refresh fluentd by delete pod
oc delete pod -l logging-infra=fluentd
