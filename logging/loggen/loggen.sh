#!/bin/bash
IMAGE=docker.io/mffiedler/ocp-logtest:latest
PROJECT=${1:-log}
oc new-project $PROJECT
curl -O https://raw.githubusercontent.com/openshift/svt/master/openshift_scalability/content/logtest/logtest-rc.json
oc new-app logtest-rc.json -n $PROJECT

echo "Ref to https://github.com/openshift/svt/blob/master/openshift_scalability/content/logtest/ocp_logtest-README.md"

