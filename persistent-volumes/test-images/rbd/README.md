Ceph RBD server pod for OpenShift testing.

# Making Ceph RBD server image
Copied from https://github.com/kubernetes/kubernetes/tree/master/test/images/volumes-tester/rbd.

# Creating Ceph RBD server pod
The rbd server pod needs `rbd` module and needs to run as `privileged` with `hostNetwork`. Follow these steps to create an RBD server pod on OpenShift 3.

```
# Edit scc.yml, replace YOUR_USERNAME with your username
oc create -f scc.yml
oc create -f rbd-server.json
oc create -f rbd-secret.yml
```

After your pod is created, run `oc get pod rbd-server -o yaml | grep podIP`, the IP address will be used for your testing pod.

# Creating testing pod
Update pod.json, replace the monitor ip with your pod ip.

```
oc create -f pod.json
oc exec -it rbd ls /mnt/rbd
```
