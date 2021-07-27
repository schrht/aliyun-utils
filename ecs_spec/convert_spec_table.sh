#!/bin/bash

# Description: Convert Alibaba ECS SPEC json to the csv.
# Maintainer: Charles Shih <schrht@gmail.com>

function show_usage() {
	echo "Convert Alibaba ECS SPEC json to the csv."
	echo "$(basename $0) <-j JSON_FILE> <-c CSV_FILE>"
}

while getopts :hj:c: ARGS; do
	case $ARGS in
	h)
		# Help option
		show_usage
		exit 0
		;;
	j)
		# Json file option
		jfile=$OPTARG
		;;
	c)
		# CSV file option
		cfile=$OPTARG
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

if [ -z $jfile ] || [ -z $cfile ]; then
	show_usage
	exit 1
fi

# Main
set -e

keys="InstanceTypeId
InstanceTypeFamily
InstanceFamilyLevel
BaselineCredit
InitialCredit
CpuCoreCount
MemorySize
GPUAmount
GPUSpec
DiskQuantity
NvmeSupport
LocalStorageAmount
LocalStorageCapacity
LocalStorageCategory
EniQuantity
EniTotalQuantity
EniIpv6AddressQuantity
EniPrivateIpAddressQuantity
EniTrunkSupported
PrimaryEniQueueNumber
SecondaryEniQueueNumber
TotalEniQueueQuantity
MaximumQueueNumberPerEni
EriQuantity
InstanceBandwidthRx
InstanceBandwidthTx
InstancePpsRx
InstancePpsTx"


# Create the table
table=""
for key in $keys; do
	table="${table}${key},"
done
table="${table%,}\n"

# Add data to the table
while read line; do
	echo -e "\nProcessing $line ..."
	flavor_json=$line

	# Query values and append to the table
	for key in $keys; do
		value=$(echo $flavor_json | jq -r ".$key")
		table="${table}${value},"
	done
	table="${table%,}\n"

done <$jfile

# Dump to a CSV file
echo -e $table >$cfile

exit 0
