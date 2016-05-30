#!/bin/bash
#set -x

echo """kind: PersistentVolume
apiVersion: v1
metadata:
  name: ebs1
  labels:
    type: local
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  awsElasticBlockStore:
    volumeID: "aws://us-east-1d/vol-d1372e72"
    fsType: "ext4"
""">pv1.yaml

#Generate pvc json file template
cat>pvc1.json<<EOF
{
    "apiVersion": "v1",
    "kind": "PersistentVolumeClaim",
    "metadata": {
        "name": "ebs1"
    },
    "spec": {
        "accessModes": [ "ReadWriteOnce" ],
        "resources": {
            "requests": {
                "storage": "1Gi"
            }
        }
    }
}
EOF
#Generate pod json file template
echo """kind: Pod
apiVersion: v1
metadata:
  name: mypod1
  labels:
    name: frontendhttp
spec:
  containers:
    - name: myfrontend
      image: aosqe/hello-openshift

      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
      - mountPath: "/tmp"
        name: aws
  volumes:
    - name: aws
      persistentVolumeClaim:
        claimName: ebs1
""">pod1.yaml


#Create 50 pv ,pvc , pod son file
for i in {2..50}
do
  cp pv1.yaml pv${i}.yaml
  cp pvc1.json pvc${i}.json
  cp pod1.yaml pod${i}.yaml
  sed -i "s/ebs1/ebs${i}/" pv${i}.yaml
  sed -i "s/ebs1/ebs${i}/" pvc${i}.json
  sed -i "s/mypod1/mypod${i}/" pod${i}.yaml
  sed -i "s/ebs1/ebs${i}/" pod${i}.yaml
done


#Generate 50 volumes
echo "create 50 volumes now"
for i in {1..50}
do
   volume=$(ec2addvol --size 1 -z us-east-1d | cut -f2)
   echo ${volume} >> volume.list
   sed -i "s/vol-d1372e72/$volume/" pv${i}.yaml
done

echo "create 50 pods now"
#Create pod
for i in {1..50}
do
   oc create -f pv${i}.yaml
done

for i in {1..50}
do
   oc create -f pvc${i}.json
done

sleep 5

for i in {1..50}
do
   oc create -f pod${i}.yaml
done

sleep 300
oc delete pods --all
sleep 30
oc delete pvc --all
oc delete pv --all
sleep 120

while read line
do
  ec2delvol $line
done<volume.list

