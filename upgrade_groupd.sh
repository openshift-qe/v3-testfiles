#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


UI_PRO=uiupgrade
DEVEXP_PRO=devexpupgrade
METERING_PRO=meteringupgrade

TEAM=none
RESULT_FILE=/tmp/upgradeData

function ui {
  echo "Collectting pre_upgrade data for UI team.... "
  echo -e "================== UI-TEAM DATA `date` ============================================" >> $RESULT_FILE

  echo -e "#oc get pods -n openshift-console -o yaml | grep console.openshift.io/image | uniq\n$(oc get pods -n openshift-console -o yaml | grep console.openshift.io/image | uniq)" >> $RESULT_FILE
  echo -e "#oc get pods -n openshift-console-operator -o yaml | grep 'image:'|uniq\n$(oc get pods -n openshift-console-operator -o yaml | grep 'image:' | uniq)" >> $RESULT_FILE
  echo -e "#oc get clusteroperator console -o yaml\n$(oc get clusteroperator console -o yaml)" >> $RESULT_FILE
  echo "==================UI team's namespace ${UI_PRO} is created!"
  oc new-project ${UI_PRO}
  echo "=================Preparing upgrade data for UI team....."
  oc new-app centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git
  oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/daemon/daemonset.yaml
  oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json
  oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/hello-deployment-1.yaml
  echo "waiting for pods running....."
  sleep 30
  echo -e "#oc get all -n ${UI_PRO}\n$(oc get all -n ${UI_PRO})" >> $RESULT_FILE
  echo "Data preparing for UI team was finished!"
  echo -e  "\033[31m Please double confirm web access work well before upgrade. The console route is https://$(oc get route -n openshift-console -l app=console | sed -n '2p'|awk '{print $2}')  \033[0m"
}


#DevExp team
function devExp {
  echo "Collectting pre_upgrade data for DevExp team.... "
  echo -e "================== DEVEXP-TEAM  DATA `date` ============================================" >> $RESULT_FILE
  echo -e "#oc get pods -o yaml -n openshift-image-registry | grep imageID |uniq\n$(oc get pods -o yaml -n openshift-image-registry | grep imageID |uniq)" >> $RESULT_FILE
  echo -e "#oc get pods -o yaml -n openshift-cluster-samples-operator | grep imageID |uniq\n$(oc get pods -o yaml -n openshift-cluster-samples-operator | grep imageID |uniq)" >> $RESULT_FILE
  echo -e "#oc get pods -n openshift-image-registry\n$(oc get pods -n openshift-image-registry)" >> $RESULT_FILE
  echo -e "#oc describe is jenkins -n openshift\n$(oc describe is jenkins -n openshift)" >> $RESULT_FILE
  echo -e "#oc describe is ruby -n openshift\n$(oc describe is ruby -n openshift)" >> $RESULT_FILE
  echo -e "#oc get pods -n openshift-controller-manager -o yaml |grep imageID |uniq\n$(oc get pods -n openshift-controller-manager -o yaml |grep imageID |uniq)" >> $RESULT_FILE
  echo -e "#oc  get pods -n openshift-controller-manager -o yaml  |grep phase:\n$(oc  get pods -n openshift-controller-manager -o yaml  |grep phase:)" >> $RESULT_FILE

  echo "================== DEVEXP team's namespace ${DEVEXP_PRO} is created!"
  oc new-project ${DEVEXP_PRO}
  echo "=================Preparing upgrade data for DEVEXP team....."
  oc patch config.samples.operator.openshift.io cluster -p '{"spec": {"skippedImagestreams": ["perl", "mysql"]}}' --type merge
  oc new-app ruby~https://github.com/openshift/ruby-ex
  oc new-app jenkins-ephemeral
  oc new-app ruby:2.2~https://github.com/openshift/ruby-hello-world --strategy=docker
  

  echo "==================waiting for pods running....."
  sleep 300
  echo "waiting ruby-ex pod running..."; podstatus=unknown; while [ ${podstatus} !=  "running" ]; do oc get pods --selector app=ruby-ex -n devexpupgrade|grep Running; if [ $? -eq 0 ]; then podstatus=running; fi; done;
  echo "waiting ruby-hello-world pod running..."; podstatus=unknown; while [ ${podstatus} !=  "running" ]; do oc get pods --selector app=ruby-hello-world -n devexpupgrade|grep Running; if [ $? -eq 0 ]; then podstatus=running; fi; done;
  echo "waiting Jenkins pod running..."; podstatus=unknown; while [ ${podstatus} !=  "running" ]; do oc get pods --selector name=jenkins -n devexpupgrade|grep Running; if [ $? -eq 0 ]; then podstatus=running; fi; done;
  echo -e "#oc get all -n ${DEVEXP_PRO} \n$(oc get all -n ${DEVEXP_PRO})" >> $RESULT_FILE
  echo "Data preparing for DEVEXP team was finished!"

}

#Monitoring
function monitoring {
  echo "Collectting pre_upgrade data for Monitoring team.... "
  echo -e "================== MONITORING-TEAM  DATA `date` ============================================" >> $RESULT_FILE
  echo -e "#oc get clusteroperator monitoring -o yaml\n$(oc get clusteroperator monitoring -o yaml)" >> $RESULT_FILE
  echo "=================Preparing upgrade data for MONITORING team....."
  oc create -f https://raw.githubusercontent.com/juzhao/monitoring/master/config.yaml
  timeout 180 bash -c 'pvcaccount=0; while [ ${pvcaccount} -lt 5 ]; do let pvcaccount=$(oc -n openshift-monitoring get pvc | grep -v NAME | wc -l); echo "waiting pvc creation successfully..."; done;'
  oc -n openshift-monitoring get pvc
  echo -e "#oc -n openshift-monitoring get pvc | grep -v NAME\n$(oc -n openshift-monitoring get pvc | grep -v NAME)" >> upgradeData
  echo -e "#for pod in \$(oc -n openshift-monitoring get pod  | grep prometheus-k8s | awk '{print \$1}'); do echo \$pod; oc -n openshift-monitoring get pod \$pod -oyaml | grep -i retention; done\n$(for pod in $(oc -n openshift-monitoring get pod  | grep prometheus-k8s | awk '{print $1}'); do echo $pod; oc -n openshift-monitoring get pod $pod -oyaml | grep -i retention; done)" >> $RESULT_FILE
  echo -e "#oc -n openshift-monitoring logs \$(oc -n openshift-monitoring get pod | grep telemeter-client | awk '{print \$1}') -c telemeter-client | grep "https://infogw.api.stage.openshift.com"\n$(oc -n openshift-monitoring logs $(oc -n openshift-monitoring get pod | grep telemeter-client | awk '{print $1}') -c telemeter-client | grep https://infogw.api.stage.openshift.com)" >> $RESULT_FILE
  echo  -e "#oc get clusteroperator monitoring -o yaml\n$(oc get clusteroperator monitoring -o yaml)" >> $RESULT_FILE
  echo "Data preparing for MONITORING team was finished!"
}

#Logging team
function es_cluster_health {
     echo -e $(oc get pods --selector component=elasticsearch -n openshift-logging |grep Running)
     timeout 60 bash -c 'es_pod=$(oc get pods --selector component=elasticsearch -n openshift-logging |grep Running); pod_name=${es_pod%% *}; es_healthy=unknown; while [ ${es_healthy} != "healthy" ]; do echo -e "#oc -n openshift-logging exec -c elasticsearch \${pod_name} -- es_cluster_health  | grep green\n$(oc -n openshift-logging exec -c elasticsearch ${pod_name} -- es_cluster_health  | grep green)"; if [ $? -eq 0 ]; then es_healthy=healthy; fi; done;'
    if [ ! $? ] ; then
      echo "elasticsearch is unhealthy!!"
      exit 1
    else
      echo "elasticsearch is healthy!!" 
    fi
}
function enableLogging {
  echo "==================Install LOGGING........"
  oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/clusterlogging/OCP-21311/namespace.yaml
  oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/clusterlogging/OCP-21311/operator-group.yaml
  oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/clusterlogging/OCP-21311/csc-clusterlogigng.yaml
  oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/clusterlogging/OCP-21311/csc-elasticsearch.yaml
  oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/clusterlogging/OCP-21311/sub-cluster-logging.yaml
  oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/clusterlogging/OCP-21311/sub-elasticsearch-operator.yaml
  sleep 30
  oc create -f https://raw.githubusercontent.com/anpingli/v3-testfiles/master/logging/clusterlogging/storageclass_name.yaml  -n openshift-logging
  echo "==================waiting for pods running....."
  timeout 300 bash -c 'echo "waiting elasticsearch pod running..."; podstatus=unknown; while [ ${podstatus} !=  "running" ]; do oc get pods --selector component=elasticsearch -n openshift-logging|grep Running; if [ $? -eq 0 ]; then podstatus=running; fi; done;'
  es_cluster_health
  timeout 10 bash -c 'echo "waiting fluentd pods running...."; podstatus=unknown; while [ ${podstatus} !=  "running" ]; do oc get pods --selector component=fluentd -n openshift-logging|grep Running; if [ $? -eq 0 ]; then podstatus=running; fi; done;'
  timeout 10 bash -c 'echo "waiting kibana pods running...."; podstatus=unknown; while [ ${podstatus} !=  "running" ]; do oc get pods --selector component=kibana -n openshift-logging|grep Running; if [ $? -eq 0 ]; then podstatus=running; fi; done;'
  if [ ! $? ] ; then
      echo "\033[31m Logging installed failed! \033[0m"
      exit 1
  fi
  echo -e  "\033[31m Logging installed successfully!  \033[0m"

}

function logging {
   echo "Collectting pre_upgrade data for LOGGING team.... "
   echo -e "================== LOGGING-TEAM  DATA `date` ============================================" >> $RESULT_FILE
   echo -e "#oc exec -c elasticsearch \$(oc get pods --selector component=elasticsearch -n openshift-logging | sed  -n 2p |awk '{print \$1 }' ) -n openshift-logging -- es_cluster_health |grep status\n$(oc exec -n openshift-logging -c elasticsearch $(oc get pods --selector component=elasticsearch -n openshift-logging | sed  -n 2p |awk '{print $1 }') -- es_cluster_health |grep status)" >> $RESULT_FILE
   echo -e "#oc exec -c elasticsearch \$(oc get pods --selector component=elasticsearch -n openshift-logging | sed  -n 2p |awk '{print \$1 }' ) -n openshift-logging -- es_util --query=_cat/indices?v\n$( oc exec  -n openshift-logging -c elasticsearch $(oc get pods --selector component=elasticsearch -n openshift-logging | sed  -n 2p |awk '{print $1 }') -- es_util --query=_cat/indices?v)" >> $RESULT_FILE
   echo -e "#oc get pods --selector component=elasticsearch -n openshift-logging\n$(oc get pods --selector component=elasticsearch -n openshift-logging)" >> $RESULT_FILE
   echo -e "#oc get pods --selector component=kibana -n openshift-logging \n$(oc get pods --selector component=kibana -n openshift-logging)" >> $RESULT_FILE
   echo -e "#oc get pods --selector component=fluentd -n openshift-logging\n$( oc get pods --selector component=fluentd -n openshift-logging)" >> $RESULT_FILE
   echo -e "#oc exec -c elasticsearch \$(oc get pods --selector component=elasticsearch -n openshift-logging | sed  -n 2p |awk '{print \$1 }') -- es_cluster_health\n$(oc exec -n openshift-logging -c elasticsearch $(oc get pods --selector component=elasticsearch -n openshift-logging | sed  -n 2p |awk '{print $1 }' ) -- es_cluster_health)" >> $RESULT_FILE
   echo -e "#oc exec -c elasticsearch \$(oc get pods --selector component=elasticsearch -n openshift-logging | sed  -n 2p |awk '{print \$1}' ) -- es_util --query=_cat/shards\n$(oc exec -n openshift-logging -c elasticsearch $(oc get pods --selector component=elasticsearch -n openshift-logging | sed  -n 2p |awk '{print $1 }' ) -- es_util --query=_cat/shards)" >> $RESULT_FILE
   echo "Data preparing for LOGGING team was finished!"
   echo -e "\033[31m Please MANUALLY access Kibana route via admin and normal useres and save some data: https://$(oc get route -n openshift-logging | sed -n 2p |  awk '{print $2 }'
) \033[0m" >> $RESULT_FILE
}

function metering {
    echo -e "================== METERING DATA `date` ============================================" 
    ssh -i libra-new.pem -t -o StrictHostKeyChecking=no -o ProxyCommand='ssh -i libra-new.pem  -A -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -W %h:%p core@$(oc get service -n openshift-ssh-bastion ssh-bastion -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")' core@$(oc get node |sed  -n 2p |awk '{print $1}') "sudo -i"
    echo -e "curl \"http://127.0.0.1:8001/api/v1/namespaces/metering-upgrade/services/https:reporting-operator:http/proxy/api/v1/reports/get?name=node-cpu-capacity\&namespace=openshift-metering\&format=csv\"\n$(curl "http://127.0.0.1:8001/api/v1/namespaces/metering-upgrade/services/https:reporting-operator:http/proxy/api/v1/reports/get?name=node-cpu-capacity&namespace=metering-upgrade&format=csv")" >> $RESULT_FILE
    echo -e "curl \"http://127.0.0.1:8001/api/v1/namespaces/metering-upgrade/services/https:reporting-operator:http/proxy/api/v1/reports/get?name=node-cpu-capacity\&namespace=openshift-metering\&format=csv\"\n$(curl "http://127.0.0.1:8001/api/v1/namespaces/metering-upgrade/services/https:reporting-operator:http/proxy/api/v1/reports/get?name=node-cpu-capacity&namespace=metering-upgrade&format=tabular")" >> $RESULT_FILE
    exit
    exit
    echo "Please copy data from  $(oc get node |sed  -n 2p |awk '{print $1}'):$RESULT_FILE to localhost: $RESULT_FILE "

}

function enablemetering {
   echo -e "Please make sure your cluster satisfy the following requirements needed by metering"
   echo -e "num_masters: 3,num_workers: 3, vm_type: m5.xlarge"
   echo -e "Please make sure you have clone the https://github.com/operator-framework/operator-metering repo."
   read -p "Please give the operator-metering directory path:" path
   export METERING_NAMESPACE=metering-upgrade
   $path/hack/install.sh
   echo "waiting pod running....."
   sleep 120
   if [ !$(oc get po -n $METERING_NAMESPACE | tail -n +2 |grep  -cvE "(Running|Completed)") ] ; then
     echo -e  "\033[31m Metering installed successfully!  \033[0m"
   else
     echo -e "\033[31m  Metering installation failed, please check!!!  \033[0m"
    fi
}

function removeTSB {
  echo "=========Removing TSB==========="
  oc delete project template-service-broker
  oc delete catalogsourceconfigs.operators.coreos.com installed-community-template-service-broker -n openshift-marketplace

}

function removeASB {
  echo "=========Removing ASB==========="
  oc delete project ansible-service-broker
  oc delete catalogsourceconfigs.operators.coreos.com installed-community-ansible-service-broker -n openshift-marketplace

}

function commonData {
  echo -e "================== COMMON DATA `date` ============================================" > $RESULT_FILE
  echo -e "#oc get clusterversion\n$(oc get clusterversion)" >> $RESULT_FILE
  echo -e "#oc get clusteroperator\n$(oc get clusteroperator)" >> $RESULT_FILE
}


function removeComponent {
  while true;
    do
      case "$COMPONENT" in
           LOGGING) removeLogging; exit 0;; #  Non-implement 
           TSB) removeTSB; exit 0;;
           ASB) removeASB; exit 0;;
           METERING) removemetering; exit 0;; # Non-implement 
           *) echo "Invalid value: Now only support to remove LOGGING|TSB|ASB|METERING component!"; exit 1;;
    esac
 done
}

function prepareDataforOneTeam {
  commonData
  while true; 
    do
      case "$TEAM" in
           UI) ui; exit 0;;
           DEVEXP) devExp; exit 0;;
           MONITORING) monitoring; exit 0;;
           LOGGING) logging; exit 0;;
	   METERING) metering; exit 0;;
	   *) echo "Invalid value: Now only support UI|DEVEXP|METERING|MONITORING|LOGGING team! Use '-h' to get help."; exit 1;;
    esac
  done
}


function prepareDataforAllTeam {
   commonData
   #enableTSB
   ui
   devExp
   monitoring
   enableLogging
   logging
   #enablemetering
   #metering # Need to double confim steps with Peter.

}

function enableComponent {
  while true; 
    do
      case "$COMPONENT" in
           LOGGING) enableLogging; exit 0;;
           TSB) enableTSB; exit 0;;
           ASB) enableASB; exit 0;;
	   METERING) enablemetering; exit 0;;
           *)
	   echo "Invalid value: Now only support to enable LOGGING|TSB|ASB|METERING component! Use '-h' to get help."; exit 1;;
    esac
 done
}

while getopts at:f:he:r: opt
  do
     case "$opt" in
       f)
       RESULT_FILE=$OPTARG
       echo "The pre-upgrade status will be record in $RESULT_FILE file!"
       ;;
       t)
       TEAM=$OPTARG
       ;;
       h)
       echo "Options:"
       echo "-a: Prepare data for all team."
       echo "-t: Please give team name which you plan to prepare data for it. UI|DEVEXP|METERING|MONITORING|LOGGING"
       echo "Noted: TSB component required by UI-team, Logging component required by Logging-team!"
       echo "-f: Please give the archive file recorded the pre-upgrade status. (default is /tmp/upgradeData)"
       echo "-e: You can enable component for upgrade. support LOGGING|TSB|ASB|METERING"
       echo "-r: You can remove specified component. support LOGGING|ASB|TSB|METERING"
       exit 0;;
       e)
       COMPONENT=$OPTARG
       enableComponent
       ;;
       r)
       COMPONENT=$OPTARG
       removeComponent
       ;;
       a)
       TEAM=all
       ;;
       ?)
       exit 1;;
  esac
done

if [ $TEAM = "all" ]
 then
  prepareDataforAllTeam
 else
  prepareDataforOneTeam
fi


