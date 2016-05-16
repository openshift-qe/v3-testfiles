#!/bin/sh

for i in {1..100}
do

  oc create -f https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/dynamic-provisioning-pvc.json
  sleep 10
  oc get pv
  namespace=`oc get pvc ebsc -o yaml | grep namespace: | cut -d" " -f4`
  pvnum=`oc get pv --no-headers | grep $namespace/ebsc | wc -l`

  if [ $pvnum == 1 ]
  then
    echo "only one pv is created for one dynamic pvc in the $i time"
    oc delete pvc ebsc
    sleep 10
  else
    echo "more than one pv is created for one dynamic pvc in the $i time"
    echo " this test case is failed"
    exit 1
  fi

done

echo "this test case is passed"
