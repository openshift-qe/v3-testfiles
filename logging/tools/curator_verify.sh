#! /bin/bash
oc project openshift-logging
es_pod1_name=$(oc get pods --selector component=elasticsearch -o jsonpath={.items[?\(@.status.phase==\"Running\"\)].metadata.name} | cut -d" " -f1)
if [ -z ${es_pod1_name} ]; then
   echo "No running ES pod can be found"
   exit
fi

function create_index()
{
   timestamp=$1
   indexname=${2:-project.test}
   es_util --query='project_x/curat
   oc exec -c elasticsearch $es_pod1_name -- es_util --query=$post_index/${indexname}.${cur_uuid}.${timestamp}/curatortest/ -d \'{ \"message\" : \"${timestamp} message\" }\' -XPOST 
}

function create_operation_index()
{
   timestamp=$1
   oc exec -c elasticsearch $es_pod1_name -- es_util --query=$post_index/.operations.${timestamp}/curatortest/ -d \'{ \"message\" : \"${timestamp} message\" }\' -XPOST 
}

function create_indices()
{

#d1=2019.05.12
cat <<EOF >index_days.list
d1=$(date -d "-1 day" +%Y.%m.%d)
d6=$(date -d "-6 day" +%Y.%m.%d)
d7=$(date -d "-7 day" +%Y.%m.%d)
d8=$(date -d "-8 day" +%Y.%m.%d)
d13=$(date -d "-13 day" +%Y.%m.%d)
d14=$(date -d "-14 day" +%Y.%m.%d)
d15=$(date -d "-15 day" +%Y.%m.%d)
d29=$(date -d "-29 day" +%Y.%m.%d)
d30=$(date -d "-30 day" +%Y.%m.%d)
d31=$(date -d "-31 day" +%Y.%m.%d)
d60=$(date -d "-60 day" +%Y.%m.%d)
EOF

    for line in `cat index_days.list`; do
       digit=${line%%=*}
       timestamp=${line##*=}
       cur_uuid=$(cat /proc/sys/kernel/random/uuid)
       oc exec -c elasticsearch $es_pod1_name -- es_util --query=.operations.${timestamp}/curatortest/ -d '{ "message" : "${timestamp} message" }' -XPOST 
       oc exec -c elasticsearch $es_pod1_name -- es_util --query=project.myapp-dev.${cur_uuid}.${timestamp}/curatortest/ -d '{ "message" : "${timestamp} message" }' -XPOST 
       oc exec -c elasticsearch $es_pod1_name -- es_util --query=project.dev.${cur_uuid}.${timestamp}/curatortest/ -d '{ "message" : "${timestamp} message" }' -XPOST 
       oc exec -c elasticsearch $es_pod1_name -- es_util --query=project.yourdev-${digit}.${cur_uuid}.${timestamp}/curatortest/ -d '{ "message" : "${timestamp} message" }' -XPOST 
       oc exec -c elasticsearch $es_pod1_name -- es_util --query=project.proddev-${digit}.${cur_uuid}.${timestamp}/curatortest/ -d '{ "message" : "${timestamp} message" }' -XPOST 
       oc exec -c elasticsearch $es_pod1_name -- es_util --query=prod-${digit}${cur_uuid}.${timestamp}/curatortest/ -d '{ "message" : "${timestamp} message" }' -XPOST 
    done
}

function refresh_curator_40()
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

oc patch configmap curator -p "$(cat logging-curator-patch.yaml)"
oc set env cronjob/curator CURATOR_LOG_LEVEL=DEBUG
oc patch cronjob/curator -p='{ "spec": { "schedule": "*/10 * * * *" } }'
}

function print_indices()
{
    oc exec -c elasticsearch $es_pod1_name --   indices
}

#############Main###########################
create_indices
print_indices | tee prior_delete.txt
refresh_curator_40
sleep 10
print_indices | tee after_delete.txt

diff prior_delete.txt after_delete.txt
