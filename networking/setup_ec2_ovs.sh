#!/bin/bash
master_dns=$1
node1_dns=$2
node2_dns=$3
CONF_DIR=/root/openshift.local.config

function get_ip() {
    local host=$1
    ssh $host "ip addr show eth0" |sed -n 3p | awk '{print $2}' | cut -d / -f 1
}

master_ip=`get_ip $master_dns`
node1_ip=`get_ip $node1_dns`
node2_ip=`get_ip $node2_dns`


function create_cert() {
    network=redhat/openshift-ovs-multitenant
    ssh $master_dns "
    /usr/bin/openshift admin ca create-master-certs --overwrite=false --public-master=https://${master_dns}:8443 --hostnames=${master_ip},${master_dns} --cert-dir=$CONF_DIR/master/
    /usr/bin/openshift start master --master=https://${master_dns}:8443 --network-plugin=${network} --write-config=$CONF_DIR/master/
    /usr/bin/openshift admin create-node-config --node-dir=$CONF_DIR/node1 --node=${node1_dns} --hostnames=${node1_dns},${node1_ip} --master=https://${master_ip}:8443 --network-plugin=${network} --node-client-certificate-authority=$CONF_DIR/master/ca.crt --certificate-authority=$CONF_DIR/master/ca.crt --signer-cert=$CONF_DIR/master/ca.crt --signer-key=$CONF_DIR/master/ca.key --signer-serial=$CONF_DIR/master/ca.serial.txt
    /usr/bin/openshift admin create-node-config --node-dir=$CONF_DIR/node2 --node=${node2_dns} --hostnames=${node2_dns},${node2_ip} --master=https://${master_ip}:8443 --network-plugin=${network} --node-client-certificate-authority=$CONF_DIR/master/ca.crt --certificate-authority=$CONF_DIR/master/ca.crt --signer-cert=$CONF_DIR/master/ca.crt --signer-key=$CONF_DIR/master/ca.key --signer-serial=$CONF_DIR/master/ca.serial.txt
"
    scp -r $master_dns:/root/openshift.local.config/ /tmp/config/
    for i in 1 2;
    do 
        eval "ssh \$node${i}_dns \"mkdir /root/openshift.local.config/\""
        eval "rsync -aqrz /tmp/config/openshift.local.config/node$i/* \$node${i}_dns:/root/openshift.local.config/node/"
    done
    rm -rf /tmp/config/*
}

function prepare_sdn() {
    system_docker_path=/usr/lib/systemd/system/docker.service.d/
    for vm in $node1_dns $node2_dns
    do
        ssh $vm "git clone https://github.com/openshift/openshift-sdn
        cp openshift-sdn/plugins/osdn/ovs/bin/* /usr/bin/
        mkdir -p $system_docker_path
        cat <<EOF > \"${system_docker_path}/docker-sdn-ovs.conf\"
[Service]
EnvironmentFile=-/run/openshift-sdn/docker-network
EOF
"
    done
}

function install_latest_origin() {
    for vm in $master_dns $node1_dns $node2_dns
    do
        ssh $vm "
        git clone https://github.com/openshift/origin/
        pushd origin
        make clean build
        cp _output/local/bin/linux/amd64/* /usr/bin/
        popd
        "
    done
}

function pre_request() {
    for vm in $node1_dns $node2_dns $master_dns
    do
        ssh $vm "yum install -y openvswitch iptables-services
        systemctl enable openvswitch
        systemctl start openvswitch
        systemctl start iptables
        cp /data/src/github.com/openshift/origin/_output/local/bin/linux/amd64/openshift /usr/bin/"
    done
}

function install_master_service() {
    ssh $master_dns "
echo 'OPTIONS=--loglevel=2
CONFIG_FILE=/root/openshift.local.config/master/master-config.yaml
' > /etc/sysconfig/openshift-master

echo '[Unit]
Description=OpenShift Master
Documentation=https://github.com/openshift/origin
After=network.target
After=etcd.service
Requires=network.target

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/openshift-master
Environment=GOTRACEBACK=crash
ExecStart=/usr/bin/openshift start master --config=\${CONFIG_FILE} \$OPTIONS
LimitNOFILE=131072
LimitCORE=infinity
WorkingDirectory=/root/
SyslogIdentifier=openshift-master
Restart=always

[Install]
WantedBy=multi-user.target
'   > /usr/lib/systemd/system/openshift-master.service
"
}

function install_node_service() {
    for i in $node1_dns $node2_dns 
    do
        ssh $i "
        echo 'OPTIONS=--loglevel=5
CONFIG_FILE=/root/openshift.local.config/node/node-config.yaml
' > /etc/sysconfig/openshift-node

echo '[Unit]
Description=OpenShift Node
After=docker.service
Wants=docker.service
Documentation=https://github.com/openshift/origin

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/openshift-node
Environment=GOTRACEBACK=crash
ExecStart=/usr/bin/openshift start node --config=\${CONFIG_FILE} \$OPTIONS
TimeoutStartSec=300
LimitNOFILE=65536
LimitCORE=infinity
WorkingDirectory=/root/
SyslogIdentifier=openshift-node
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
'   > /usr/lib/systemd/system/openshift-node.service
"
    done
}

function open_iptables() {
    for i in $node1_dns $node2_dns $master_dns
    do
        ssh $i "    
        iptables -I INPUT -p tcp -m multiport --ports 10250,10251,10252,4001,8443,4789,80,443,1936 -j ACCEPT
        iptables-save > /etc/sysconfig/iptables
        systemctl restart iptables
        "
    done
}

function start_services() {
    for i in $master_dns $node1_dns $node2_dns
    do
        ssh $i "systemctl start openshift-master || systemctl restart openshift-node"
    done
}

pre_request
install_latest_origin
create_cert
open_iptables
prepare_sdn
install_master_service
install_node_service
start_services
