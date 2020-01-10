#!/bin/bash
registry=${1:-"origin"}
image_version=${2:-":latest"}
#image_version="@sha256:xxxx"

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

echo 'apiVersion: v1
kind: Namespace
metadata:
  name: openshift-operators-redhat
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-logging: "true"
    openshift.io/cluster-monitoring: "true"'|oc create -f -

oc project openshift-operators-redhat

echo '---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: elasticsearch-operator' |oc create -f -

echo '---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: elasticsearch-operator
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
  - pods/exec
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
  - monitoring.coreos.com
  resources:
  - prometheusrules
  - servicemonitors
  verbs:
  - "*"
- apiGroups:
  - rbac.authorization.k8s.io
  resources:
  - clusterroles
  - clusterrolebindings
  verbs:
  - "*"
- nonResourceURLs:
  - "/metrics"
  verbs:
  - get
- apiGroups:
  - authentication.k8s.io
  resources:
  - tokenreviews
  - subjectaccessreviews
  verbs:
  - create
- apiGroups:
  - authorization.k8s.io
  resources:
  - subjectaccessreviews
  verbs:
  - create'|oc create -f -

echo '---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: elasticsearch-operator-rolebinding
subjects:
- kind: ServiceAccount
  name: elasticsearch-operator
  namespace: openshift-logging
roleRef:
  kind: ClusterRole
  name: elasticsearch-operator
  apiGroup: rbac.authorization.k8s.io' | oc create -f -

echo '---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: elasticsearches.logging.openshift.io
spec:
  group: logging.openshift.io
  names:
    kind: Elasticsearch
    listKind: ElasticsearchList
    plural: elasticsearches
    singular: elasticsearch
  scope: Namespaced
  version: v1'|oc create -f -

echo "---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch-operator
spec:
  replicas: 1
  selector:
    matchLabels:
      name: elasticsearch-operator
  template:
    metadata:
      labels:
        name: elasticsearch-operator
    spec:
      serviceAccountName: elasticsearch-operator
      containers:
        - name: elasticsearch-operator
          image: ${registry_url}elasticsearch-operator${image_version}
          imagePullPolicy: IfNotPresent
          command:
          - elasticsearch-operator
          ports:
          - containerPort: 60000
            name: metrics
          env:
            - name: WATCH_NAMESPACE
              value: ''
            - name: OPERATOR_NAME
              value: elasticsearch-operator
            - name: PROXY_IMAGE
              value: ${registry_url}oauth-proxy${image_version}
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name" | oc create -f -
