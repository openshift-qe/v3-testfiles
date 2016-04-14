#!/bin/bash
admin_conf=./admin.kubeconfig
project=bmengpr

function check_router() {
    while [ `oc get po -n default --config $admin_conf | grep router | grep Running | wc -l` -eq 0 ]
    do 
            echo "Router is not ready"
            sleep 5
    done
}

function get_router_ip() {
    router_host=$(oc get po -n default --config $admin_conf -o wide | grep router | grep Running | awk '{print $6}')
    router_ip=()
    for i in ${router_host[*]}
    do
                router_ip+=(`ping -c 1 $i | grep icmp | cut -d \( -f2 | cut -d \) -f1`)
    done
}

function modify_scc() {
    curl -s https://raw.githubusercontent.com/bmeng/mytestfiles/master/my-scc.json | sed s/bmengp1/$project/g | oc create -f - -n default --config $admin_conf
}

function wait_for_running() {
    while [ `oc get po -n $project | grep -v NAME | grep -v Running | wc -l` -ne 0 ]
           do sleep 10
    done
}  

function access_via_router() {
    local app_dns=$1
    local port=$2
    local router_ip=$3
    local app_url=$4
    local other=$5
    curl -s --resolve $app_dns:$port:$router_ip $app_url $other -c cookies    >> routing_log
}

function access_via_cookies() {
    local app_dns=$1
    local port=$2
    local router_ip=$3
    local app_url=$4
    local other=$5
    curl -s --resolve $app_dns:$port:$router_ip $app_url $other -b cookies    >> routing_log
}


function clean_account() {
    oc delete project --all
    sleep 15
}


function unsecure_route() {
    local app_url=bmeng.example.com
    oc new-project ${project}
    curl -s https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/list_for_unsecure.json | sed s/www.example.com/$app_url/g| oc create -f - 
    wait_for_running
    echo UNSECURE >> routing_log
    for i in {1..6} ; do access_via_router $app_url 80 ${router_ip[`shuf -i 0-1 -n 1`]} http://$app_url/ ; done
    for i in {1..6} ; do access_via_cookies $app_url 80 ${router_ip[`shuf -i 0-1 -n 1`]} http://$app_url/ ; done
    echo >> routing_log
}


function edge_route() {
    local app_url=bmengedge.example.com
    oc new-project ${project}
    curl -s https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/list_for_edge.json | sed s/www.example.com/$app_url/g| oc create -f - 
    wait_for_running
    echo EDGE >> routing_log
    for i in {1..6} ; do access_via_router $app_url 443 ${router_ip[`shuf -i 0-1 -n 1`]} https://$app_url/ -k ; done
    for i in {1..6} ; do access_via_cookies $app_url 443 ${router_ip[`shuf -i 0-1 -n 1`]} https://$app_url/ -k ; done
    echo >> routing_log
}

function reencrypt_route() {
    local app_url=bmengre.example2.com
    oc new-project ${project}
    curl -s https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/list_for_reencrypt.json | sed s/www.example2.com/$app_url/g| oc create -f - 
    wait_for_running
    echo REENCRYPT >> routing_log
    for i in {1..6} ; do access_via_router $app_url 443 ${router_ip[`shuf -i 0-1 -n 1`]} https://$app_url/ -k ; done
    for i in {1..6} ; do access_via_cookies $app_url 443 ${router_ip[`shuf -i 0-1 -n 1`]} https://$app_url/ -k ; done
    echo >> routing_log
}


rm -rf routing_log
check_router
get_router_ip
modify_scc
unsecure_route
clean_account
edge_route
clean_account
reencrypt_route
clean_account
