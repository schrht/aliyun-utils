#!/bin/bash

function show_usage() {
    echo -e "Usage: $0 <instance family or instance type>"
}

if [ -z "$1" ]; then
    show_usage
    exit 1
fi

if [ ! -z "$(echo $1 | cut -d. -f3)" ]; then
    # instance type provisioned
    type_name=$1
    family_name=${1%.*}
    family_name=${family_name%-*}
else
    # instance family provisioned
    type_name=""
    family_name=$1
fi

echo -e "\nQuerying information for $family_name family..."

# get the json block for instance family
x=$(aliyun ecs DescribeInstanceTypes --InstanceTypeFamily $family_name)
[ $? = 0 ] || exit 1
family_block=$(echo $x | jq -r '.InstanceTypes.InstanceType[]')

# get instance type list
instance_types=$(echo $family_block | jq -r '.InstanceTypeId')

# prepare yaml file
yamlf=/tmp/alibaba_flavors.yaml.tmp$$
echo "Flavor: !mux" >$yamlf

# handle specified instance types
for instance_type in $instance_types; do
    if [ ! -z "$type_name" ] && [ "$type_name" != "$instance_type" ]; then
        # skip the mismatched ones for specified instance type
        continue
    fi

    # get the json block for instance type
    type_block=$(echo $family_block | jq -r ". | select( \
.InstanceTypeId==\"$instance_type\")")

    # gather information
    InstanceTypeId=$(echo $type_block | jq -r '.InstanceTypeId')
    CpuCoreCount=$(echo $type_block | jq -r '.CpuCoreCount')
    MemorySize=$(echo $type_block | jq -r '.MemorySize')
    LocalStorageAmount=$(echo $type_block | jq -r '.LocalStorageAmount')
    LocalStorageCapacity=$(echo $type_block | jq -r '.LocalStorageCapacity')
    LocalStorageCategory=$(echo $type_block | jq -r '.LocalStorageCategory')
    EniQuantity=$(echo $type_block | jq -r '.EniQuantity')
    EniTotalQuantity=$(echo $type_block | jq -r '.EniTotalQuantity')

    if [ ! -z "$LocalStorageCategory" ] &&
        [ "$LocalStorageCategory" = "local_ssd_pro" ]; then
        LocalStorageCategory=ssd
    else
        echo "error: unknown LocalStorageCategory ($LocalStorageCategory)"
        exit 1
    fi
done

# Target:
# ----------
# Flavor: !mux
#     ecs.i1-c10d1.8xlarge:
#         name: ecs.i1-c10d1.8xlarge
#         cpu: 32
#         memory: 128
#         disk_count: 2
#         disk_size: 1456
#         disk_type: ssd
#         nic_count: 8
#     ecs.hfg5.xlarge:
#         name: ecs.hfg5.xlarge
#         cpu: 4
#         memory: 16

exit 0
