#!/bin/bash

# Description: Select an Available Zone for speified flavor.
# Maintainer: Charles Shih <schrht@gmail.com>

SOURCE_PATH=$(dirname ${BASH_SOURCE[0]})
PATH=$SOURCE_PATH/../cli_utils:$PATH
PATH=$SOURCE_PATH/../aliyun_list_flavors:$PATH

DSTRIBUTION_FILE=/tmp/aliyun_instance_distribution.txt
ELIGIBLE_ZONES_FILE=./eligible_zones.txt

function show_usage() {
    echo "Select an Available Zone for speified flavor."
    echo "$(basename $0) <-f FLAVOR>"
}

while getopts :hf: ARGS; do
    case $ARGS in
    h)
        # Help option
        show_usage
        exit 0
        ;;
    f)
        # Flavor option
        flavor=$OPTARG
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

# Parse params
if [ -z $flavor ]; then
    show_usage
    exit 1
fi

# Main

# Create flavor distribution file if not exist
if [ ! -f $DSTRIBUTION_FILE ]; then
    echo "INFO: Creating $DSTRIBUTION_FILE" >&2
    query_available_flavors.sh -o $DSTRIBUTION_FILE >&2
fi

# Get all available zones
echo "INFO: Querying available zones." >&2
grep -w $flavor $DSTRIBUTION_FILE | cut -d, -f1 |
    sort -u >/tmp/scheduler_$$_zones.txt
len=$(cat /tmp/scheduler_$$_zones.txt | wc -l)
lst=$(cat /tmp/scheduler_$$_zones.txt | xargs echo)
if [ $len -gt 0 ]; then
    echo "INFO: Got $len zone(s): \"$lst\"." >&2
else
    echo "INFO: No zone is available for \"$flavor\"." >&2
    rm -f /tmp/scheduler_$$_*
    exit 1
fi

# Filter eligible zones
if [ -f $ELIGIBLE_ZONES_FILE ]; then
    echo "INFO: Filtering eligible zones." >&2
    grep -f $ELIGIBLE_ZONES_FILE /tmp/scheduler_$$_zones.txt > \
        /tmp/scheduler_$$_eligible_zones.txt
    len=$(cat /tmp/scheduler_$$_eligible_zones.txt | wc -l)
    lst=$(cat /tmp/scheduler_$$_eligible_zones.txt | xargs echo)
else
    echo "INFO: Skip filtering eligible zones." >&2
    cp /tmp/scheduler_$$_zones.txt /tmp/scheduler_$$_eligible_zones.txt
fi
if [ $len -gt 0 ]; then
    echo "INFO: Got $len zone(s): \"$lst\"." >&2
else
    echo "INFO: No zone is available for \"$flavor\"." >&2
    rm -f /tmp/scheduler_$$_*
    exit 1
fi

# Pick up a zone
echo "INFO: Randomly pick up a zone." >&2
idx=$(($RANDOM % len)) && idx=$((idx + 1))
random_zone=$(sed -n "${idx}p" /tmp/scheduler_$$_eligible_zones.txt)
echo "INFO: Picked \"$random_zone\" from $len zone(s)." >&2

# Set results
selected_zone=$random_zone
echo "INFO: Selected \"$selected_zone\"." >&2
echo $selected_zone
rm -f /tmp/scheduler_$$_*
exit 0
