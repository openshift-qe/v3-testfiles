Must run as privileged container to enable rbd mount.

Kube-apiserver and kubelet must be start with `--allow=privileged=true` flag, eg
```
/root/kubernetes/_output/local/bin/linux/amd64/kube-apiserver --v=3 --cert-dir=/var/run/kubernetes --service-account-key-file=/tmp/kube-serviceaccount.key --service-account-lookup=false --admission-control=NamespaceLifecycle,NamespaceAutoProvision,LimitRanger,SecurityContextDeny,ServiceAccount,DenyEscalatingExec,ResourceQuota --insecure-bind-address=127.0.0.1 --insecure-port=8080 --etcd-servers=http://127.0.0.1:4001 --service-cluster-ip-range=10.0.0.0/24 --cors-allowed-origins=/127.0.0.1(:[0-9]+)?$,/localhost(:[0-9]+)?$ --allow-privileged=true

/root/kubernetes/_output/local/bin/linux/amd64/kubelet --v=3 --chaos-chance=0.0 --container-runtime=docker --rkt-path= --rkt-stage1-image= --hostname-override=127.0.0.1 --address=127.0.0.1 --api-servers=127.0.0.1:8080 --port=10250 --allow=privileged=true
```
