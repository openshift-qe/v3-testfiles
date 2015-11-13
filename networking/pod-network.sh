#!/bin/bash
admin_conf=./admin.kubeconfig

function access_in_pod() {
	pod_ips=`for i in 1 2 3 4; do oc get po -o yaml -n bmengu1p$i ; done | grep podIP | cut -d ':' -f 2 | sed ':a;N;s/\n//g;ta'`
	service_ips=`for i in 1 2 3 4 ; do oc get svc  -n bmengu1p$i ; done | awk '{print $2}' | grep -v CLUSTER | sed ':a;N;s/\n/ /g;ta'`
	for i in 1 2 3 4
	do 
		oc project bmengu1p$i
		pod_name=`oc get po -n bmengu1p$i| grep test-rc | sed -n 1p | cut -d ' ' -f1`
		new_pod_name=`oc get po -n bmengu1p$i| grep new-test-rc | sed -n 1p | cut -d ' ' -f1`
		oc exec -t $pod_name -- bash -c "for ip in $pod_ips ; do curl --connect-timeout 1 \$ip:8080 ; done" >> result.log
		oc exec -t $new_pod_name -- bash -c "for ip in $service_ips ; do curl --connect-timeout 1 \$ip:27017 ; done" >> result.log
		echo >> result.log
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

function pod_join_network() {
	create_1st_round

	oadm pod-network join-projects --to bmengu1p1 bmengu1p3 bmengu1p4 --config $admin_conf
	
	create_2nd_round

	echo > result.log	

	access_in_pod
	clean_account
	mv result.log pod_join_network.log
}

function pod_join_network_by_selector() {
        create_1st_round

	oc label ns bmengu1p2 ns=uni --config $admin_conf
	oc label ns bmengu1p4 ns=uni --config $admin_conf
	oadm pod-network join-projects --to bmengu1p1 --selector ns=uni --config $admin_conf
        
        create_2nd_round

        echo > result.log

	access_in_pod
	clean_account
        mv result.log pod_join_network_selector.log
}

function pod_make_globel() {
        create_1st_round

	oadm pod-network make-projects-global bmengu1p2 --config $admin_conf

        create_2nd_round

        echo > result.log
	access_in_pod
	clean_account
        mv result.log pod_make_global.log
}

function pod_make_global_by_selector() {
	create_1st_round
	
        oc label ns bmengu1p2 ns=uni --config $admin_conf
        oc label ns bmengu1p4 ns=uni --config $admin_conf
        oadm pod-network make-projects-global --selector ns=uni --config $admin_conf

	create_2nd_round

	echo > result.log
	access_in_pod
	clean_account
	mv result.log pod_make_global_by_selector.log
}


pod_join_network
pod_join_network_by_selector
pod_make_globel
pod_make_global_by_selector
