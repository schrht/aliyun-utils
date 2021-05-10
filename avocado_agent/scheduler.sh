#!/bin/bash

# Description: Schedule containerized avocado-cloud tests.
# Maintainer: Charles Shih <schrht@gmail.com>

SOURCE_PATH=$(dirname ${BASH_SOURCE[0]})
PATH=$SOURCE_PATH/../cli_utils:$PATH
PATH=$SOURCE_PATH/../aliyun_list_flavors:$PATH

SCHEDULER_PROFILE=./scheduler.profile
ELIGIBLE_ZONES_FILE=./eligible_zones.txt
CONTAINER_LIST_FILE=./container_list.txt

function show_usage() {
    echo "Schedule containerized avocado-cloud tests."
    echo "$(basename $0) <-m IMAGE_NAME> <-f FLAVORS>"
}

while getopts :hm:f: ARGS; do
    case $ARGS in
    h)
        # Help option
        show_usage
        exit 0
        ;;
    m)
        # Image option
        image=$OPTARG
        ;;
    f)
        # Flavor option
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

# Parse params
if [ -z "$image" ] || [ -z "$flavors" ]; then
    show_usage
    exit 1
fi

function select_container() {
    echo "INFO: Selecting an available container." >&2

    if [ -z "$CONTAINER_NAMES" ]; then
        echo "ERROR: \$CONTAINER_NAMES is not set." >&2
        return 1
    fi

    local inused_containers=$(podman ps --format "{{.Names}}")

    local container
    for container in $CONTAINER_NAMES; do
        if (echo "$inused_containers" | grep -q -x $container); then
            echo "INFO: Container \"$container\" is in-used." >&2
            continue
        else
            echo "INFO: Selected container \"$container\"." >&2
            echo $container
            return 0
        fi
    done

    echo "INFO: No available container." >&2
    return 1
}

# Main

# Check workspace

if [ ! -f $SCHEDULER_PROFILE ]; then
    echo "ERROR: SCHEDULER_PROFILE($SCHEDULER_PROFILE) is not found." >&2
    exit 1
fi
if [ ! -f $ELIGIBLE_ZONES_FILE ]; then
    echo "WARN: ELIGIBLE_ZONES_FILE($ELIGIBLE_ZONES_FILE) is not found." >&2
fi

source $SCHEDULER_PROFILE

# [ -z "$FLAVORS" ] && echo "\$FLAVORS is not set." && exit 1

len=0
for flavor in $flavors; do len=$((len + 1)); done

num=0
for flavor in $flavors; do
    num=$((num + 1))
    echo "($num/$len) $flavor"
    echo "===================="

    # demo
    az=$(select_az.sh -f $flavor)
    con=$(select_container)
    echo "Flavor $flavor will be tested in $az with container $con"

    continue

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
