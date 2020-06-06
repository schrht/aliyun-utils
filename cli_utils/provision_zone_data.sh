#!/bin/bash

codepath=$(dirname $0)
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

# Get data
regionid=$(az_to_region $azid)
vswid=$(az_to_vsw $azid)
sgid=$(az_to_sg $azid)

# Provision data
sed -e "s/\(az: \).*$/\1$azid/" \
	-e "s/\(region: \).*$/\1$regionid/" \
	-e "s/\(id: \)vsw-.*$/\1$vswid/" \
	-e "s/\(id: \)sg-.*$/\1$sgid/" \
	--in-place=.bak $file
