IMAGE=docker.io/mffiedler/ocp-logtest:latest
PROJECT=${1:-syslog}
oc new-project $PROJECT
oc adm policy add-scc-to-user privileged -z default
curl -O https://raw.githubusercontent.com/openshift/svt/master/openshift_scalability/content/logtest/logtest-syslog-rc.json
sed -i '/--fixed-line/s/--num-lines/--journal --num-lines/' logtest-syslog-rc.json
oc new-app logtest-syslog-rc.json -n $PROJECT
echo "Ref to https://github.com/openshift/svt/blob/master/openshift_scalability/content/logtest/ocp_logtest-README.md"
