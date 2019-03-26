PROJECT=${1:-syslog}
oc new-project $PROJECT
oc adm policy add-scc-to-user privileged -z default
oc new-app -f  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/loggen/journald_log_apps.json
