#!/bin/bash

# enable dbus
mkdir /run/dbus
dbus-daemon --system

# iscsi vars
TARGET_NAME='iqn.2016-04.test.com:storage.target00'
ACL_IQN='iqn.2016-04.test.com:test.img'
AUTH_USER_ID=5f84cec2
AUTH_PASSWORD=b0d324e9

mkdir /iscsi_disks

# Create backstores
targetcli /backstores/fileio create disk01 /iscsi_disks/disk01.img 2G
# Create iscsi target
targetcli /iscsi create ${TARGET_NAME}
# Set IP address of the target
targetcli /iscsi/${TARGET_NAME}/tpg1/portals delete 0.0.0.0 3260
targetcli /iscsi/${TARGET_NAME}/tpg1/portals create `hostname -i`
# Set LUN
targetcli /iscsi/${TARGET_NAME}/tpg1/luns create /backstores/fileio/disk01
# Set ACL
targetcli /iscsi/${TARGET_NAME}/tpg1/acls create ${ACL_IQN}
# Set auth
targetcli /iscsi/${TARGET_NAME}/tpg1/acls/${ACL_IQN} set auth userid=${AUTH_USER_ID}
targetcli /iscsi/${TARGET_NAME}/tpg1/acls/${ACL_IQN} set auth password=${AUTH_PASSWORD}


while true
do
    sleep 30
done
