#!/bin/sh
echo "--delete: `date --rfc-3339=ns` Processing resource after deletion (\$1:$1 \$2:$2 \$3:$3) ..." >> log
# Other processing ...
grep -vE "^$1/$2 " inventory > newinventory
mv -f newinventory inventory
