#!/bin/bash

cat <<EOF > rsyslogserver.yaml
kind: Template
apiVersion: v1
metadata:
  name: rsyslogserver-template
  namespace: openshift-logging
  annotations:
    description: "A rsyslogserver to received clusterlogging forward messages."
    tags: "rsyslogserver"
objects:
- kind: ConfigMap
  apiVersion: v1
  metadata:
    name: ${NAME}-main
    namespace: openshift-logging
    labels:
      provider: aosqe
      component: "rsyslogserver"
  data:
    rsyslog.conf: |+
      global(processInternalMessages="on")
      module(load="imptcp")
      module(load="imudp" TimeRequery="500")
      module(load="omstdout")

      input(type="imptcp" port="514")
      input(type="imudp" port="514")
      action(type="omstdout")
- kind: ConfigMap
  apiVersion: v1
  metadata:
    name: ${NAME}-bin
    namespace: openshift-logging
    labels:
      provider: aosqe
      component: "rsyslogserver"
  data:
    rsyslog.sh: "#!/bin/bash \n exec /usr/sbin/rsyslogd -f /etc/rsyslog/conf/rsyslog.conf -n"

- kind: Deployment
  apiVersion: extensions/v1beta1
  metadata:
    name:  ${NAME}
    namespace: openshift-logging
    labels:
      provider: aosqe
      component: "rsyslogserver"
      appname: ${NAME}
  spec:
    replicas: 1
    revisionHistoryLimit: 10
    selector:
      matchLabels:
        provider: aosqe
        component: "rsyslogserver"
    strategy:
      type: Recreate
    template:
      metadata:
        labels:
          provider: aosqe
          component: "rsyslogserver"
          appname: ${NAME}
      spec:
        serviceAccount: rsyslogserver
        serviceAccountName: rsyslogserver
        containers:
        - name: "rsyslog"
          args:
          - /opt/app-root/bin/rsyslog.sh
          command:
          - /bin/sh
          image: docker.io/viaq/rsyslog:latest
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
            procMount: Default
          ports:
          - containerPort: 514
            name: rsyslog-pod
          volumeMounts:
          - mountPath: /etc/rsyslog/conf
            name: main
            readOnly: true
          - mountPath: /opt/app-root/bin
            name: bin
            readOnly: true
        volumes:
        - configMap:
            defaultMode: 420
            name: ${NAME}-main
          name: main
        - configMap:
            defaultMode: 420
            name: ${NAME}-bin
          name: bin

- apiVersion: v1
  kind: Service
  metadata:
    annotations:
      description: Exposes and load balances the application pods
    labels:
      provider: aosqe
      component: "rsyslogserver"
    name: ${NAME}
  spec:
    ports:
    - name: ${NAME}
      port: 514
      targetPort: 514
    selector:
      appname: ${NAME}
      provider: aosqe
parameters:
- description: The name assigned to all of the object 
  displayName: Name
  name: NAME
  required: true
  value: rsyslogserver
EOF

oc new-app -f rsyslogserver.yaml
