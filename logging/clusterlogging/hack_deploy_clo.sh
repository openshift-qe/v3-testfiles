#!/bin/bash
registry=${1:-"origin"}
image_version=${2:-":latest"}
branch="4.3"
#image_version="@sha256:xxxx"

if [[ X"$registry" == X"internal" ]]; then
    registry_url="image-registry.openshift-image-registry.svc:5000/openshift/ose-"
fi

if [[ X"$registry" == X"origin" ]]; then
    registry_url="quay.io/openshift/origin-"
fi

if [[ X"$registry" == X"brew" ]]; then
    registry_url="registry-proxy.engineering.redhat.com/rh-osbs/openshift3-ose-"
fi

if [[ X"$registry" == X"stage" ]]; then
    registry_url="registry.stage.redhat.io/openshif4/ose-"
fi

if [[ X"$registry" == X"prod" ]]; then
    registry_url="registry.redhat.io/openshift3/ose-"
fi

echo '
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-logging
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-logging: "true"
    openshift.io/cluster-monitoring: "true"' |oc create -f -

oc project openshift-logging
if [[ $branch == "4.3" ]]; then
    oc create -f https://raw.githubusercontent.com/openshift/cluster-logging-operator/release-4.3/manifests/4.3/0100_clusterroles.yaml
    oc create -f https://raw.githubusercontent.com/openshift/cluster-logging-operator/release-4.3/manifests/4.3/0110_clusterrolebindings.yaml
    oc create -f https://raw.githubusercontent.com/openshift/cluster-logging-operator/release-4.3/manifests/4.3/cluster-loggings.crd.yaml
    oc create -f https://raw.githubusercontent.com/openshift/cluster-logging-operator/release-4.3/manifests/4.3/collectors.crd.yaml
    oc create -f https://raw.githubusercontent.com/openshift/cluster-logging-operator/release-4.3/manifests/4.3/logforwardings.crd.yaml
fi

echo 'apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-logging-operator' |oc create -f -

echo '---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: cluster-logging-operator
rules:
- apiGroups:
  - logging.openshift.io
  resources:
  - "*"
  verbs:
  - "*"
- apiGroups:
  - ""
  resources:
  - pods
  - services
  - endpoints
  - persistentvolumeclaims
  - events
  - configmaps
  - secrets
  - serviceaccounts
  verbs:
  - "*"
- apiGroups:
  - apps
  resources:
  - deployments
  - daemonsets
  - replicasets
  - statefulsets
  verbs:
  - "*"
- apiGroups:
  - route.openshift.io
  resources:
  - routes
  - routes/custom-host
  verbs:
  - "*"
- apiGroups:
  - batch
  resources:
  - cronjobs
  verbs:
  - "*"' |oc create -f -

echo '---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: cluster-logging-operator-priority
rules:
- apiGroups:
  - scheduling.k8s.io
  resources:
  - priorityclasses
  verbs:
  - "*" '| oc create -f -

echo '---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: cluster-logging-operator-rolebinding
subjects:
- kind: ServiceAccount
  name: cluster-logging-operator
roleRef:
  kind: Role
  name: cluster-logging-operator
  apiGroup: rbac.authorization.k8s.io'|oc create -f  -

echo '---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: cluster-logging-operator-priority-rolebinding
subjects:
- kind: ServiceAccount
  name: cluster-logging-operator
  namespace: cluster-logging
roleRef:
  kind: ClusterRole
  name: cluster-logging-operator-priority' | oc create -f -

echo "apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: cluster-logging-operator
  namespace: openshift-logging
spec:
  replicas: 1
  selector:
    matchLabels:
      name: cluster-logging-operator
  template:
    metadata:
      labels:
        name: cluster-logging-operator
    spec:
      serviceAccountName: cluster-logging-operator
      containers:
      - name: cluster-logging-operator
        image: ${registry_url}cluster-logging-operator${image_version}
        imagePullPolicy: IfNotPresent
        command:
        - cluster-logging-operator
        env:
          - name: WATCH_NAMESPACE
            value: openshift-logging
          - name: POD_NAME
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: metadata.name
          - name: OPERATOR_NAME
            value: cluster-logging-operator 
          - name: ELASTICSEARCH_IMAGE
            value: ${registry_url}logging-elasticsearch5${image_version}
          - name: FLUENTD_IMAGE
            value: ${registry_url}logging-fluentd${image_version}
          - name: KIBANA_IMAGE
            value: ${registry_url}logging-kibana5${image_version}
          - name: CURATOR_IMAGE
            value: ${registry_url}logging-curator5${image_version}
          - name: OAUTH_PROXY_IMAGE
            value: ${registry_url}oauth-proxy${image_version}
          - name: PROMTAIL_IMAGE
            value: ${registry_url}promtail${image_version}
" | oc apply -f -
