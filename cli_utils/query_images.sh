#!/bin/bash

# Description: Query images from the specified region.
# Maintainer: Charles Shih <schrht@gmail.com>

function show_usage() {
    echo "Query images from the specified region."
    echo "$(basename $0) [-h] <-r region> [-a]"
    echo "-a: query images for all platforms rather than Red Hat."
}

while getopts :hr:a ARGS; do
    case $ARGS in
    h)
        # Help option
        show_usage
        exit 0
        ;;
    r)
        # region
        region=$OPTARG
        ;;
    a)
        # all
        all=true
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

if [ -z $region ]; then
    show_usage
    exit 1
fi

# Main
source ./cli_utils.sh

_is_region $region
if [ "$?" != "0" ]; then
    echo "$(basename $0): invalid region id -- $region" >&2
    exit 1
fi

# Query and get image id list
x=$(aliyun ecs DescribeImages --RegionId $region --PageSize 100)
if [ "$?" != "0" ]; then
    echo "$(basename $0): Failed to run Aliyun API." >&2
    exit 1
fi

if [ "$all" = "true" ]; then
    id_list=$(echo $x | jq -r '.Images.Image[].ImageId')
else
    # Platform is "Red Hat" only
    id_list=$(echo $x | jq -r '.Images.Image[] | select(.Platform=="Red Hat") | .ImageId')
fi

# Query image one-by-one and add data into a table
for id in $id_list; do
    x=$(aliyun ecs DescribeImages --RegionId $region --ImageId $id)
    if [ "$?" != "0" ]; then
        echo "$(basename $0): Failed to run Aliyun API." >&2
        exit 1
    fi

    name=$(echo $x | jq -r '.Images.Image[].ImageName')
    id=$(echo $x | jq -r '.Images.Image[].ImageId')
    ostype=$(echo $x | jq -r '.Images.Image[].OSType')
    platform=$(echo $x | jq -r '.Images.Image[].Platform' | tr ' ' '_')
    status=$(echo $x | jq -r '.Images.Image[].Status')

    table="${table}$(printf '%s,%s,%s,%s,%s' $name $id $ostype $platform $status)\n"
done

# Show the table contents with format
echo -e $table | sort -t , -k 4 |
    column -t -s , -N ImageName,ImageId,OSType,Platform,Status

exit 0