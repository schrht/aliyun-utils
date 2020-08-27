#!/bin/bash

codepath=$(dirname $(which $0))
source $codepath/cli_utils.sh

# Parse params
image_name="$1"
if [ -z "$image_name" ]; then
	echo "Arg1: image name is needed."
	exit 1
fi

_is_region "$2" && region_id="$2"
if [ -z "$region_id" ]; then
	echo "Arg2: Region ID is needed."
	exit 1
fi

if [ ! -z "$3" ]; then
	file="$3"
else
	echo "Arg3: YAML file is not spcified, using './alibaba_common.yaml'."
	file=./alibaba_common.yaml
fi

if [ ! -f $file ]; then
	echo "$file is not a validate file."
	exit 1
fi

# Get image ID
image_id=$(image_name_to_id $image_name $region_id)

# Check data
[ "$region_id" = "null" ] && echo "Can not get valided Region ID." && exit 1
[ "$image_id" = "null" ] && echo "Can not get valided Image ID." && exit 1

# Get RHEL version
rehl_ver=$(echo $image_name | sed 's/.*[A-Za-z][._-]\([0-9]\)[._-]\([0-9]\)[._-].*/\1.\2/')

# Guess username
if [[ $image_name =~ _alibase_ ]] || [[ $image_name =~ _alibaba_ ]]; then
	username=root
else
	username=cloud-user
fi

# Provision data
sed -e "s/{{ rehl_ver }}/$rehl_ver/" \
	-e "s/{{ username }}/$username/" \
	-e "s/{{ image_name }}/$image_name/" \
	-e "s/{{ image_id }}/$image_id/" \
	--in-place=.bak $file

exit 0
