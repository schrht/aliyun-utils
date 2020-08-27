#!/bin/bash

codepath=$(dirname $(which $0))
source $codepath/cli_utils.sh

# Parse params
_is_az "$1" && azid="$1"
if [ -z "$azid" ]; then
	echo "Arg1: AZID is needed."
	exit 1
fi

if [ ! -z "$2" ]; then
	file="$2"
else
	echo "Arg2: YAML file is not spcified, using './alibaba_common.yaml'."
	file=./alibaba_common.yaml
fi

if [ ! -f $file ]; then
	echo "$file is not a validate file."
	exit 1
fi

# Get data
regionid=$(az_to_region $azid)
vswid=$(az_to_vsw $azid)
sgid=$(az_to_sg $azid)

# Check data
[ "$vswid" = "null" ] && echo "Can not get valided VSwitch ID." && exit 1
[ "$sgid" = "null" ] && echo "Can not get valided Security Group ID." && exit 1

# Provision data
sed -e "s/\(az: \).*$/\1$azid/" \
	-e "s/\(region: \).*$/\1$regionid/" \
	-e "s/\(id: \)vsw-.*$/\1$vswid/" \
	-e "s/\(id: \)sg-.*$/\1$sgid/" \
	--in-place=.bak $file

exit 0

