#!/bin/bash

CONTAINERS="ac1 ac2"
FLAVOR_MAPPING_FILE="../aliyun_list_flavors/available_flavors.txt"
AVAILABLE_REGIONS="cn-hangzhou cn-shenzhen cn-beijing"
OCCUPIED_REGIONS="cn-beijing"

function info() {
	echo $@ >&2
}

function pick_container() {
	for container in $CONTAINERS; do
		podman ps -a --format "{{.Names}}" | grep -q -x $container
		[ "$?" = "0" ] && continue
		info "INFO: Picked available container $container"
		echo $container
		return 0
	done
	info "INFO: No available container."
	return 1
}

function get_available_zones() {
	# $1: flavor
	zones=$(grep $1 $FLAVOR_MAPPING_FILE | cut -d, -f1)
	echo $zones
}

#container=$(pick_container)
#echo $container
get_available_zones ecs.i2.xlarge


