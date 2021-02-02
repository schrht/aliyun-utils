#!/bin/bash

# Description: Query Alibaba ECS SPEC and dump to a json file.
# Maintainer: Charles Shih <schrht@gmail.com>
# Requirement: aliyuncli, jq

function show_usage() {
	echo "Query Alibaba ECS SPEC and dump to a json file."
	echo "$(basename $0) <-f JSON_FILE> <-l FLAVOR_LIST>"
}

while getopts :hf:l: ARGS; do
	case $ARGS in
	h)
		# Help option
		show_usage
		exit 0
		;;
	f)
		# Json file option
		file=$OPTARG
		;;
	l)
		# Flavor list option
		flavors=$OPTARG
		;;
	"?")
		echo "$(basename $0): unknown option: $OPTARG" >&2
		;;
	":")
		echo "$(basename $0): option requires an argument -- '$OPTARG'" >&2
		echo "Try '$(basename $0) -h' for more information." >&2
		exit 1
		;;
	*)
		# Unexpected errors
		echo "$(basename $0): unexpected error -- $ARGS" >&2
		echo "Try '$(basename $0) -h' for more information." >&2
		exit 1
		;;
	esac
done

if [ -z $file ] || [ -z $flavors ]; then
	show_usage
	exit 1
fi

function show_family_name() {
	local flavor=$1
	local family
	family=${flavor%.*}
	family=${family%-*}
	echo $family
}

function update_family_data() {
	# This function takes a family name and updates $family_* variables.

	family_name=$1
	# get the data of the instance family
	echo -e "\nGetting the information of $family_name family..."
	local x=$(aliyun ecs DescribeInstanceTypes \
		--InstanceTypeFamily $family_name)
	if [ $? = 0 ]; then
		family_json=$(echo $x | jq -r '.InstanceTypes.InstanceType[]')
		family_flavors=$(echo $family_json | jq -r '.InstanceTypeId')
		return 0
	else
		unset family_json
		unset family_flavors
		return 1
	fi
}

function get_flavor_json() {
	# Description:
	#   This function takes a flavor name and returns the json block.
	# Calls:
	#   show_family_name()
	#   update_family_data()
	# Input:
	#   $1 - flavor name
	# Output:
	#	$flavor_json

	# Parse params
	local flavor=$1

	# Get family name and update the family data if needed
	local family=$(show_family_name $flavor)
	[ "$family" != "$family_name" ] && update_family_data $family

	# Get the flavor json block
	flavor_json=$(echo $family_json | jq -r ". | select( \
		.InstanceTypeId==\"$flavor\")")
}

# Main

: >$file

for flavor in $flavors; do
	echo -e "\nProcessing $flavor ..."

	# Get the flavor json block
	get_flavor_json $flavor

	# Append to the output file
	echo $flavor_json >>$file
done

exit 0
