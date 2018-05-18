# Quickstart
Install required packages on your node:

`yum -y install iscsi-initiator-utils`

## Configure iscsi initiator on your node
```
echo 'InitiatorName=iqn.2015-06.world.server:www.server.world' > /etc/iscsi/initiatorname.iscsi
```

Edit `/etc/iscsi/iscsid.conf`

line #54: node.session.auth.authmethod = CHAP

line #58,59:
```
node.session.auth.username = openshift
node.session.auth.password = redhat
```

## Login target
```
systemctl start iscsid
systemctl enable iscsid
iscsiadm -m discovery -t sendtargets -p 192.168.0.225
iscsiadm -m node -o show
iscsiadm -m node --login
iscsiadm -m session -o show
```
## Make file system
```
parted --script /dev/sda "mklabel msdos"
parted --script /dev/sda "mkpart primary 0% 100%"
mkfs.ext4 /dev/sda
mount /dev/sda /mnt
df -hT
```


# Create pod
`oc create -f pod.json`

# Doc reference
[iscsi target](http://www.server-world.info/en/note?os=Fedora_21&p=iscsi)

[iscsi initiator](http://www.server-world.info/en/note?os=Fedora_21&p=iscsi&f=2)
