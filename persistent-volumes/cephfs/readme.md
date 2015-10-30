# prepare ceph required packages on all nodes

```
yum install -y python-jinja2 redhat-lsb-core hdparm gdisk boost-system python-requests cryptsetup boost-thread fuse fuse-libs

cat << EOF > /etc/yum.repos.d/ceph.repo
[ceph]
name=Ceph packages for 
baseurl=http://ceph.com/rpm-firefly/rhel7/\$basearch
enabled=1
priority=2
gpgcheck=1
type=rpm-md
gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=http://ceph.com/rpm-firefly/rhel7/noarch
enabled=1
priority=2
gpgcheck=1
type=rpm-md
gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=http://ceph.com/rpm-firefly/rhel7/SRPMS
enabled=0
priority=2
gpgcheck=1
type=rpm-md
gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc
EOF

yum -y install ceph-fuse --disablerepo=rhel-7
```

# Create pods
If you have a different ceph cluster setup, fetch the admin keyring: `ceph-authtool -p /etc/ceph/ceph.client.admin.keyring`, with the keyring, replace the content in `secret.yaml`.

Also, update `pod.yaml` with your real monitor IPs.

```
oc create -f secret.yaml
oc create -f pod.yaml
```
