#!/bin/bash

# Description: Schedule containerized avocado-cloud tests.
# Maintainer: Charles Shih <schrht@gmail.com>

SOURCE_PATH=$(dirname ${BASH_SOURCE[0]})
PATH=$SOURCE_PATH/../cli_utils:$PATH
PATH=$SOURCE_PATH/../aliyun_list_flavors:$PATH

SCHEDULER_PROFILE=./scheduler.profile
ELIGIBLE_ZONES_FILE=./eligible_zones.txt
INUSED_ZONES_FILE=./inused_zones.txt
FLAVOR_TODO_FILE=./flavor_todo.txt
FLAVOR_TEST_FILE=./flavor_test.txt
FLAVOR_PASS_FILE=./flavor_pass.txt
FLAVOR_FAIL_FILE=./flavor_fail.txt

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

    local inused_containers=$(podman ps -a --format "{{.Names}}")

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

function run() {
    # Get a flavor
    local flavor=$(head -n 1 $FLAVOR_TODO_FILE)
    if [ -z $flavor ]; then
        echo "INFO: No more flavors in TODO list." >&2
        return 0
    else
        echo "INFO: Got \"$flavor\" from TODO list." >&2
    fi

    # Deal with lists
    echo "INFO: Label \"$flavor\" change list: TODO -> TEST" >&2
    sed -i "/^$flavor$/d" $FLAVOR_TODO_FILE
    echo $flavor >>$FLAVOR_TEST_FILE

    # Select container and zone
    local container=$(select_container)
    if [ -z $container ]; then
        echo "INFO: Label \"$flavor\" change list: TEST -> TODO" >&2
        sed -i "/^$flavor$/d" $FLAVOR_TEST_FILE
        echo $flavor >>$FLAVOR_TODO_FILE
        return 0
    fi

    local zone=$(select_az.sh -f $flavor)
    if [ -z $zone ]; then
        echo "INFO: Label \"$flavor\" change list: TEST -> TODO" >&2
        sed -i "/^$flavor$/d" $FLAVOR_TEST_FILE
        echo $flavor >>$FLAVOR_TODO_FILE
        return 0
    fi

    # Prepare the environment
    echo "INFO: [$container] Prepare test environment for \"$flavor\"." >&2
    # provision_flavor_data.sh $flavor \
    #     ./$contianer/data/alibaba_flavors.yaml
    sleep 1
    if [ $? != 0 ]; then
        echo "ERROR: [$container] Failed to provision flavor data!"
        echo "INFO: Label \"$flavor\" change list: TEST -> FAIL" >&2
        sed -i "/^$flavor$/d" $FLAVOR_TEST_FILE
        echo $flavor >>$FLAVOR_FAIL_FILE
        return 0
    fi

    # Execute the test
    echo "INFO: [$container] Test for \"$flavor\" started." >&2
    nohup podman run --name $container --rm -it fedora /usr/bin/sleep 1m >>$container.nohup
    local result=$?

    # podman run --name $CONTAINER_NAME --rm -it \
    #     -v ./$contianer/data:/data:rw \
    #     -v ./$contianer/job-results:/root/avocado/job-results:rw \
    #     avocado-cloud:latest /bin/bash ./container/bin/test_alibaba.sh
    echo "INFO: [$container] Test for \"$flavor\" finished." >&2

    if [ $result = 0 ]; then
        echo "INFO: Label \"$flavor\" change list: TEST -> PASS" >&2
        sed -i "/^$flavor$/d" $FLAVOR_TEST_FILE
        echo $flavor >>$FLAVOR_PASS_FILE
        return 0
    else
        echo "INFO: Label \"$flavor\" change list: TEST -> FAIL" >&2
        sed -i "/^$flavor$/d" $FLAVOR_TEST_FILE
        echo $flavor >>$FLAVOR_FAIL_FILE
        return 0
    fi

    # testinfo_path=$PWD/$CONTAINER_NAME/job-results/latest/testinfo
    # mkdir -p $testinfo_path
    # cp $PWD/$CONTAINER_NAME/data/alibaba_common.yaml $testinfo_path
    # cp $PWD/$CONTAINER_NAME/data/alibaba_flavors.yaml $testinfo_path
    # cp $PWD/$CONTAINER_NAME/data/alibaba_testcases.yaml $testinfo_path
}

while true; do
    run &
    sleep 5
done

exit 0
