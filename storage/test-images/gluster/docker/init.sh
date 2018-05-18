#!/bin/bash

LOG_FILE=/var/log/glusterd.log

touch ${LOG_FILE}
glusterd -LDEBUG --log-file=${LOG_FILE}
gluster volume create testvol `hostname -i`:/vol force
gluster volume start testvol

while true
do
    sleep 30
done
