#! /bin/bash
from_registry=brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888/openshift
to_registry=default-route-openshift-image-registry.apps.qeoanli.qe.devcluster.openshift.com/openshift
images="ose-logging-fluentd ose-logging-elasticsearch5 ose-logging-kibana5 ose-logging-curator5 ose-logging-rsyslog  ose-cluster-logging-operator  ose-cluster-logging-operator ose-oauth-proxy"
tags="latest v4.1"
for image in ${images}; do
   for tag in ${tags}; do
     docker pull $from_registry/$image:${tag}  
     docker tag $from_registry/$image:${tag}   $to_registry/$image:${tag}
     docker push $to_registry/$image:${tag}
   done
done
