#!/bin/bash
#
# Description:
#   Find best region to go based on instace types in full.txt and pass.txt
#

PATH=$PATH:.

[ "$1" = "-f" ] && flavor=$2
[ "$1" = "-z" ] && zone=$2

[ -f ./pass.txt ] && grep -v -f ./pass.txt ./full.txt > /tmp/todo.txt || cat ./full.txt > /tmp/todo.txt

resource_matrix=/tmp/aliyun_flavor_distribution.txt
if [ -f $resource_matrix ]; then
	echo "Notice: '$resource_matrix' was updated at $(stat -c %z $resource_matrix)." >&2
	echo "Notice: You might consider running 'query_flavors.sh' again to get the latest status." >&2
else
	query_flavors.sh >&2 || exit 1
fi

# get matrix
grep -f /tmp/todo.txt $resource_matrix > /tmp/matrix.txt

# show status
if [ ! -z $flavor ]; then
	# show flavor status
	echo -e "======\nFLAVOR STATUS\n------\n$flavor:" >&2
	grep $flavor /tmp/matrix.txt | cut -d, -f1
fi


# show zone status
if [ ! -z $zone ]; then
	echo -e "======\nZONE STATUS\n------\n$zone:" >&2
	grep $zone /tmp/matrix.txt | cut -d, -f2
fi

# get best region
if [ -z $flavor ] && [ -z $zone ]; then
	echo -e "======\nBEST REGIONS\n------" >&2
	cat /tmp/matrix.txt | cut -d, -f1 | uniq -c | sort -nr
fi

exit 0

