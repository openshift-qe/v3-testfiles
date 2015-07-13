# About
Test files for NFS persistent volumes for Kubernetes and OpenShift

# Steps
## via PV and PVC
1. Create a PersistentVolume: `osc create -f nfs.yaml`
2. Create a PersistentVolumeClaim: `osc create -f claim.yaml`
3. Create a pod: `osc create -f pod-with-claim.yaml`

## via Pod directly
`osc create -f pod-with-nfs.yaml`
