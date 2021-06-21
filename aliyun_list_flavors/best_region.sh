#!/bin/bash
#
# Description:
#   Find best region to go based on instace types in full.txt and pass.txt
#

PATH=$PATH:.

[ -f ./pass.txt ] && grep -v -f ./pass.txt ./full.txt > /tmp/todo.txt || cat ./full.txt > /tmp/todo.txt

resource_matrix=/tmp/aliyun_flavor_distribution.txt
if [ -f $resource_matrix ]; then
	echo "Notice: '$resource_matrix' was updated at $(stat -c %z $resource_matrix)." >&2
	echo "Notice: You might consider running 'query_flavors.sh' again to get the latest status." >&2
else
	query_flavors.sh || exit 1
fi

for flavor in $(cat /tmp/todo.txt); do
	echo -e "------\n$flavor:"
	grep $flavor $resource_matrix | cut -d, -f1
done

# get best region
echo "======"
grep -f /tmp/todo.txt $resource_matrix | cut -d, -f1 | uniq -c | sort -nr

exit 0
