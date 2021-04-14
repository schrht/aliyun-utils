#!/bin/bash
#
# Description:
#   Find best region to go based on instace types in full.txt and pass.txt
#

PATH=$PATH:.

[ -f ./pass.txt ] && grep -v -f ./pass.txt ./full.txt > /tmp/todo.txt || cat ./full.txt > /tmp/todo.txt

echo -e "\nNotice: 'available_flavors.txt' was changed on $(stat -c %z available_flavors.txt)" 
echo -e "With time passes you may want to run './query_available_flavors.sh -o available_flavors.txt' again..."

for flavor in $(cat /tmp/todo.txt); do
	echo -e "------\n$flavor:"
	grep $flavor ./available_flavors.txt | cut -d, -f1
done

# get best region
echo "======"
grep -f /tmp/todo.txt ./available_flavors.txt | cut -d, -f1 | uniq -c | sort -nr

exit 0
