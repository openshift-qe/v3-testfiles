#!/bin/bash

function wait_for_running() {
        while [ `oc get po | grep -v NAME | grep -v Running | wc -l` -ne 0 ]
                do sleep 10
        done
}

function clean_account() {
	oc delete project --all
}


function service_to_external_service() {
oc new-project bmengtestpro1
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json
wait_for_running
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service.json

pod_name=`oc get po | grep -v NAME | sed -n 1p | cut -d ' ' -f1`
service_ip=`oc get svc | grep -v CLUSTER | awk '{print $2":"$4}' | cut -d / -f1`
oc exec -t $pod_name -- bash -c "curl --connect-timeout 4 $service_ip"

clean_account
}

function service_to_other_pod() {
oc new-project bmengexu1p1
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json
wait_for_running
target_pod_ip=`oc get po -o yaml | grep podIP | cut -d: -f2 | tr -d ' '`

oc new-project bmengexu1p2
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json
curl -s https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_pod.json | sed "s/#POD_IP/$target_pod_ip/g" | oc create -f -
wait_for_running

pod_name=`oc get po | grep -v NAME | sed -n 1p | cut -d ' ' -f1`
service_ip=`oc get svc | grep -v CLUSTER | awk '{print $2":"$4}' | cut -d / -f1`
oc exec -t $pod_name -- bash -c "curl --connect-timeout 4 $service_ip"

clean_account
}

function service_to_other_service() {
oc new-project bmengesu1p1
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json
wait_for_running
target_service_ip=`oc get svc | grep -v CLUSTER | awk '{print $2}'`

oc new-project bmengesu1p2
oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json
wait_for_running
curl -s https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_service.json | sed "s/#SERVICE_IP/$target_service_ip/g" | oc create -f -

pod_name=`oc get po | grep -v NAME | sed -n 1p | cut -d ' ' -f1`
service_ip=`oc get svc | grep -v CLUSTER | awk '{print $2":"$4}' | cut -d / -f1`
oc exec -t $pod_name -- bash -c "curl --connect-timeout 4 $service_ip"

clean_account
}

clean_account
service_to_external_service
service_to_other_pod
service_to_other_service
