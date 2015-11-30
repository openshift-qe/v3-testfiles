#1/bin/bash

num_of_pods=50
template=/tmp/pod.json

function create() {
for i in $(seq 1 $num_of_pods)
do
    cat <<EOF >$template
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "pod$i",
    "creationTimestamp": null,
    "labels": {
      "name": "hello-openshift"
    }
  },
  "spec": {
    "containers": [
      {
        "name": "hello-openshift",
        "image": "aosqe/hello-openshift",
        "ports": [
          {
            "containerPort": 8080,
            "protocol": "TCP"
          }
        ],
        "resources": {},
        "volumeMounts": [
          {
            "name":"tmp",
            "mountPath":"/tmp"
          }
        ],
        "terminationMessagePath": "/dev/termination-log",
        "imagePullPolicy": "IfNotPresent",
        "securityContext": {
          "capabilities": {},
          "privileged": false
        }
      }
    ],
    "volumes": [
      {
        "name":"tmp",
        "emptyDir": {}
      }
    ],
    "restartPolicy": "Always",
    "dnsPolicy": "ClusterFirst",
    "serviceAccount": ""
  },
  "status": {}
}
EOF

oc create -f $template
sleep 5

done
}

function delete() {
    for i in $(seq 1 $num_of_pods)
    do
        oc delete pod pod$i
    done
}


# Call functions

#create
#delete
