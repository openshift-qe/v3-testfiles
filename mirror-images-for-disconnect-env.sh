#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


echo -e "\033[44;37mPlease make sure your have configured auth and CA for mirror registry!\033[0m"

MODULE=none
PLATFORM=vsphere
RESULT_FILE=/tmp/error_mirror.log
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
MIRROR_REGISTRY=none
VERSION=none
function ui {
  echo "Mirror images for UI team.... "
  listui=("origin-metering-ansible-operator:4.2" "origin-metering-reporting-operator:4.2" "origin-metering-presto:4.2" "origin-metering-hive:4.2" "origin-metering-hadoop:4.2") 
  for item in ${listui[@]}
  do
    oc image mirror quay.io/openshift/${item} ${MIRROR_REGISTRY}/openshift/${item}
    if [ $? -ne 0 ]; then
      echo TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")  >> $RESULT_FILE
      echo -e "${item} image mirrors failed, please try it again.\n#oc image mirror quay.io/openshift/${item} ${MIRROR_REGISTRY}/openshift/${item}" >> $RESULT_FILE
    fi     
  done
}

function devExp {
  echo "Mirror images for DEVEXP team.... "
  listdexp1=("ruby-23-rhel7:latest" "ruby-24-rhel7:latest" "ruby-25-rhel7:latest" "nodejs-8-rhel7:latest" "perl-524-rhel7:latest" "perl-526-rhel7:latest" "php-70-rhel7:latest" "php-71-rhel7:latest" "php-72-rhel7:latest" "mariadb-102-rhel7:latest" "mongodb-32-rhel7:latest" "mongodb-34-rhel7:latest" "mongodb-36-rhel7:latest" "mysql-57-rhel7:latest" "mysql-80-rhel7:latest" "nginx-110-rhel7:latest" "nginx-112-rhel7:latest" "postgresql-10-rhel7:latest" "postgresql-96-rhel7:latest" "python-27-rhel7:latest" "python-35-rhel7:latest" "python-36-rhel7:latest" "redis-32-rhel7:latest" "httpd-24-rhel7:latest")
  for item in ${listdexp1[@]}
  do
    oc image mirror registry.redhat.io/rhscl/${item} ${MIRROR_REGISTRY}/rhscl/${item}
    if [ $? -ne 0 ]; then
      echo TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")  >> $RESULT_FILE
      echo -e "${item} image mirrors failed, please try it again.\n#oc image mirror registry.redhat.io/rhscl/${item} ${MIRROR_REGISTRY}/rhscl/${item}" >> $RESULT_FILE
    fi
  done
}

function jenkins {
  echo "Mirror images for jenkins module.... "
  echo "You need config ci registry auth for this module"
  listjenkins=`oc adm release info --pullspecs registry.svc.ci.openshift.org/ocp/release:$VERSION | grep  jenkins| awk -F"/" '{print $3}'`
  for item in ${listjenkins[@]}
  do
    oc image mirror quay.io/openshift-release-dev/$item ${MIRROR_REGISTRY}/openshift-release-dev/ocp-v4.0-art-dev
    if [ $? -ne 0 ]; then
      echo TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")  >> $RESULT_FILE
      echo -e "${item} image mirrors failed, please try it again.\n#oc image mirror quay.io/openshift-release-dev/$item ${MIRROR_REGISTRY}/openshift-release-dev/ocp-v4.0-art-dev" >>$RESULT_FILE
    fi
  done
}
function prepareDataforOneModule {
  while true; 
    do
      case "$MODULE" in
           UI) ui; exit 0;;
           DEVEXP) devExp; exit 0;;
           JENKINS) jenkins; exit 0;;
	   *) echo "Invalid value: Now only support UI|DEVEXP|JENKINS module! Use '-h' to get help."; exit 1;;
    esac
  done
}


function prepareDataforAllModules {
   ui
   devExp
   jenkins
}


while getopts hf:p:m:v:a:o: opt
  do
     case "$opt" in
       f)
       RESULT_FILE=$OPTARG
       echo "The mirror failed images will be record in $RESULT_FILE file!"
       ;;
       m)
       MODULE=$OPTARG
       ;;
       o)
       OTHER_MIRROR_REGISTRY=$OPTARG
       ;;
       p)
       PLATFORM=$OPTARG
       ;;
       v)
       VERSION=$OPTARG
       ;;
       h)
       echo "Options:"
       echo "-f: Please give the archive file recorded the mirror failed images. (default is /tmp/error_mirror.log)"
       echo "-m: Please give module name which you plan to mirror images for. UI|DEVEXP|JENKINS"
       echo "-p: The platform the disconnect env built in.. support vsphere|baremetal"
       echo "-v: When use jenkins module, must provide payload version"
       echo "-o: When platform are aws, gcp, azure, need specify the mirror registry"
       exit 0;;
       a)
       MODULE=all
       ;;
       ?)
       exit 1;;
  esac
done

case "$PLATFORM" in
     vsphere)
       MIRROR_REGISTRY="mirror-registry.qe.devcluster.openshift.com:5001"
       ;;
     baremetal)
       MIRROR_REGISTRY="internal-registry.qe.devcluster.openshift.com:5000"
       ;; 
     other)
       echo "The platform like aws, gcp, azure have random and temporary mirror registries"
       MIRROR_REGISTRY=${OTHER_MIRROR_REGISTRY}
       ;; 
     *)
       echo "Invalid value: Now only support vsphere|baremetal|other platform! Use '-h' to get help.";exit 1
       ;;
esac

if [ $MODULE = "all" ]
 then
  prepareDataforAllModules
 else
  prepareDataforOneModule
fi
