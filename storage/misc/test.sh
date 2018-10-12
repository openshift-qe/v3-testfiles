#!/bin/bash

for i in `seq 1 10`;
do
    oc new-project test$i
    oc project test$i
    oc new-app --template=jenkins-persistent
done
