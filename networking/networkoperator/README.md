#### Store the templates for the network.operator.config.io custom resource.

#### Will be used during the cluster installation, for changing the lower level network configs which cannot be modified in `install-config.yml`.

# Usage: 
1. Generate the manifests on the currect working dir, you can either use a prepared `install-config.yml` or generate it interactively. <br />
> \# openshift-install create manifests

2. Copy the template in the dir to the `manifests/cluster-network-03-config.yaml` <br />
> \# cp $template manifests/cluster-network-03-config.yaml

3. Finish the installation <br />
> \# openshift-install create cluster
