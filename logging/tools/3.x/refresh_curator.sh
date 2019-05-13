#!/bin/bash
set -x
#Create some bogus index by different name and different date with ElasticSearch API.
if [ ! -e admin.kubeconfig ]; then
   master=$(grep openshift_logging_master_public_url hosts | awk -F"=" '{print $2}')
   master=${master:-\$master_public_url}
   echo "no admin.kubeconfig in current directory,please login as cluster-admin"
   echo "oc login $master admin.kubeconfig"
   exit 1
fi
export KUBECONFIG=admin.kubeconfig

logging_namespace=$(grep -E "^openshift_logging_namespace=" hosts | awk -F"=" '{print $2}')
logging_namespace=${logging_namespace#-openshift-logging}
oc project $logging_namespace

function refresh_curator_37()
{
#set curator to invoke deletion in 5 minutes
timezone='America/New_York'
hm5=$(TZ=${timezone} date -d "+5 minute" +%H%M)
cat <<EOF >logging-curator-patch.yaml
data:
  config.yaml: |
    myapp-dev:
      delete:
        days: 1

    .operations:
      delete:
        weeks: 1

    .defaults:
      delete:
        days: 7
      runhour: ${hm5:0:2}
      runminute: ${hm5:2:2}
      timezone: ${timezone}
kind: ConfigMap
EOF
oc set env deploymentconfig/logging-curator CURATOR_LOG_LEVEL=DEBUG
oc patch configmap logging-curator -p "$(cat logging-curator-patch.yaml)"
oc delete pod --selector logging-infra=curator
}


function refresh_curator_310()
{
#set curator to invoke deletion in 5 minutes
timezone='America/New_York'
hm5=$(TZ=${timezone} date -d "+5 minute" +%H%M)
cat <<EOF >logging-curator-patch.yaml
data:
  config.yaml: |
    myapp-dev:
      delete:
        days: 1

    .operations:
      delete:
        weeks: 1

    .defaults:
      delete:
        days: 7
      runhour: ${hm5:0:2}
      runminute: ${hm5:2:2}
      timezone: ${timezone}

    .regex:
      - pattern: '^project\..+\-dev.*\..*$'
        delete:
          days: 31
      - pattern: '.*prod.*\..*$'
        delete:
          months: 1
kind: ConfigMap
EOF
oc set env deploymentconfig/logging-curator CURATOR_LOG_LEVEL=DEBUG
oc patch configmap logging-curator -p "$(cat logging-curator-patch.yaml)"
oc delete pod --selector logging-infra=curator
}

function refresh_curator_311()
{
cat <<EOF >logging-curator-patch.yaml
data:
  config.yaml: |
    myapp-dev:
      delete:
        days: 1

    .operations:
      delete:
        weeks: 1

    .defaults:
      delete:
        days: 7
    .regex:
      - pattern: '^project\..+\-dev.*\..*$'
        delete:
          days: 31
      - pattern: '.*prod.*\..*$'
        delete:
          months: 1
kind: ConfigMap
EOF

oc patch configmap logging-curator -p "$(cat logging-curator-patch.yaml)"
oc set env cronjob/logging-curator CURATOR_LOG_LEVEL=DEBUG
oc patch cronjob/logging-curator -p='{ "spec": { "schedule": "*/10 * * * *" } }'
}
