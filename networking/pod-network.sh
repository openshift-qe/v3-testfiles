#!/bin/bash
admin_conf=./admin.kubeconfig
result_log=./pod_network_log

function check_admin_kubeconfig() {
    oc get po --config $admin_conf
    if [ $? -ne 0 ]
    then
        echo -e "\e[1;31mMissing/incorrect admin.kubeconfig in current wd.\e[0m"
        exit 1
    fi
}

function access_in_pod() {
    pod_ips=`for i in 1 2 3 4; do oc get po -o yaml -n bmengu1p$i ; done | grep podIP | cut -d ':' -f 2 | sed ':a;N;s/\n//g;ta'`
    service_ips=`for i in 1 2 3 4 ; do oc get svc  -n bmengu1p$i ; done | awk '{print $2}' | grep -v CLUSTER | sed ':a;N;s/\n/ /g;ta'`
    for i in 1 2 3 4
    do 
        oc project bmengu1p$i
        pod_name=`oc get po -n bmengu1p$i| grep test-rc | sed -n 1p | cut -d ' ' -f1`
        new_pod_name=`oc get po -n bmengu1p$i| grep new-test-rc | sed -n 1p | cut -d ' ' -f1`
        echo "POD" >> $result_log 
        oc exec -t $pod_name -- bash -c "for ip in $pod_ips ; do curl --connect-timeout 1 \$ip:8080 ; done" >> $result_log
        echo "SERVICE" >> $result_log
        oc exec -t $new_pod_name -- bash -c "for ip in $service_ips ; do curl --connect-timeout 1 \$ip:27017 ; done" >> $result_log
        echo >> $result_log
    done	
}

function access_service_in_pod() {
    service_ips=`for i in 1 2 3 4 ; do oc get svc  -n bmengu1p$i ; done | awk '{print $2}' | grep -v CLUSTER | sed ':a;N;s/\n/ /g;ta'`
    for i in 1 2 3 4
    do 
        oc project bmengu1p$i
        pod_name=`oc get po -n bmengu1p$i| grep test-rc | sed -n 1p | cut -d ' ' -f1`
        echo "SERVICE" >> $result_log
        oc exec -t $pod_name -- bash -c "for ip in $service_ips ; do curl --connect-timeout 1 \$ip:27017 ; done" >> $result_log
        echo >> $result_log
    done	
}

function clean_account() {
    oc delete project --all
    sleep 15
}

function wait_for_running() {
    while [ `for i in 1 2 3 4; do oc get po -n bmengu1p$i ; done | grep -v NAME | grep -v Running | wc -l` -ne 0 ]
        do sleep 10
    done
}

function create_1st_round() {
    for i in 1 2 3 4
    do
        oc new-project bmengu1p$i
        oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json -n bmengu1p$i
        sleep 2
    done
	
    sleep 10
}

function create_2nd_round() {
    for i in 1 2 3 4
    do
        curl -s https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json | sed 's/test-/new-test-/g' | oc create -f - -n bmengu1p$i
 	    sleep 2
    done
    sleep 10
    wait_for_running       
}

function project_join_network() {
    create_1st_round

    echo "access after create:" >> $result_log
    access_in_pod
    access_service_in_pod

    oadm pod-network join-projects --to bmengu1p1 bmengu1p3 bmengu1p4 --config $admin_conf
    create_2nd_round
	
    echo >> $result_log	
    echo "project_join_network 3 4 to 1" >> $result_log

    access_in_pod
    clean_account
	
    echo >> $result_log
}

function project_join_network_by_selector() {
    create_1st_round
    oc label ns bmengu1p2 ns=uni --config $admin_conf
    oc label ns bmengu1p4 ns=uni --config $admin_conf
    oadm pod-network join-projects --to bmengu1p1 --selector ns=uni --config $admin_conf
    create_2nd_round

    echo >> $result_log
    echo "project_join_network_by_selector 2 4 to 1" >> $result_log

    access_in_pod
    clean_account
    
    echo >> $result_log
}

function make_project_globel() {
    create_1st_round
 
    oadm pod-network make-projects-global bmengu1p2 --config $admin_conf
    create_2nd_round
    
    echo >> $result_log
    echo "make_project_global 2" >> $result_log

    access_in_pod
    clean_account
    
    echo >> $result_log
}

function make_project_global_by_selector() {
    create_1st_round
 
    oc label ns bmengu1p2 ns=uni --config $admin_conf
    oc label ns bmengu1p4 ns=uni --config $admin_conf
    oadm pod-network make-projects-global --selector ns=uni --config $admin_conf
    create_2nd_round
    
    echo >> $result_log
    echo "make_project_global_selector 2 4" >> $result_log

    access_in_pod
    clean_account

    echo >> $result_log
}

rm -rf $result_log
check_admin_kubeconfig
project_join_network
project_join_network_by_selector
make_project_globel
make_project_global_by_selector
