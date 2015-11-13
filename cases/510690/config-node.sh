#!/bin/bash -x

# Run this script on node
if ! ( rpm -qa | grep -q nfs-utils )
then
  yum install -y nfs-utils
fi

if ( getsebool virt_use_nfs | grep -q off )
then
  setsebool -P virt_use_nfs 1
fi
