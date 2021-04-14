#!/bin/bash

# Description: Run avocado-cloud against specified flavors with container.

set -e

[ -z "$FLAVORS" ] && echo "\$FLAVORS is not set." && exit 1
[ -z "$CONTAINER_NAME" ] && echo "\$CONTAINER_NAME is not set." && exit 1

for flavor in $FLAVORS; do
	echo "===================="
	provision_flavor_data.sh $flavor $PWD/$CONTAINER_NAME/data/alibaba_flavors.yaml
	echo
	echo "Current alibaba_flavors.yaml:"
	cat $PWD/$CONTAINER_NAME/data/alibaba_flavors.yaml
	echo

	ln=$(wc -l $PWD/$CONTAINER_NAME/data/alibaba_flavors.yaml | awk '{print $1}')
	[ $ln -lt 3 ] && echo -e "Skip this run.\n" && continue

	podman run --name $CONTAINER_NAME --rm -it \
		-v $PWD/$CONTAINER_NAME/data:/data:rw \
		-v $PWD/$CONTAINER_NAME/job-results:/root/avocado/job-results:rw \
		avocado-cloud:latest /bin/bash ./container/bin/test_alibaba.sh || echo -e "Please check!\n"

	testinfo_path=$PWD/$CONTAINER_NAME/job-results/latest/testinfo
	mkdir -p $testinfo_path
	cp $PWD/$CONTAINER_NAME/data/alibaba_common.yaml $testinfo_path
	cp $PWD/$CONTAINER_NAME/data/alibaba_flavors.yaml $testinfo_path
	cp $PWD/$CONTAINER_NAME/data/alibaba_testcases.yaml $testinfo_path
done

exit 0
