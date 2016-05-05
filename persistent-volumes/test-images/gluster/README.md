# GlusterFS server pod

## Creating GlusterFS server pod for OpenShift

The GlusterFS server pod **must** run as privileged container, otherwise it can not create the gluster volume when the container starts. To allow privileged containers on OpenShift, run `oc edit scc restricted`, set `allowPrivilegedContainer: true` and save. Then create the GlusterFS server pod with `oc create -f glusterd.json`. Once the server pod is created, get its podIP with `oc get pod glusterd -o yaml | grep podIP`. Edit the `endpoints.json`, set `"ip": "$YOUR_IP"` in the json and save, finally create this endpoints with `oc create -f endpoints.json`

Your GlusterFS server pod should be ready!

## Testing the GlusterFS server pod

The `pod.json` is a sample that mounts the GlusterFS volume the server pod provides, run `oc create -f pod.json`, when the pod is *Running*, you should be able to access its mount directory.
