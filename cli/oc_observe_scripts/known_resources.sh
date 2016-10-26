#!/bin/sh
echo >> log
echo "--names:  `date --rfc-3339=ns`" >> log
touch inventory
cut -f 1 -d ' ' inventory
