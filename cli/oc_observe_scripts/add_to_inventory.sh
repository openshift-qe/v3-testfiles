#!/bin/sh
echo "--CMD:    `date --rfc-3339=ns` \$1=$1, \$2=$2, \$3=$3" >> log
echo "$1/$2 $3" >> inventory
sort -u inventory -o inventory
