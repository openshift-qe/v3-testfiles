IMAGE=docker.io/mffiedler/ocp-logtest:latest
PROJECT=${1:-jsonlog}
oc new-project $PROJECT
oc new-app json_log_apps.json -n $PROJECT
