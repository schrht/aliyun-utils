function _is_az() {
	[[ "$1" = *-*-*[a-z] ]] && return 0 || return 1
}

function az_to_region() {
	# Get Region ID by Zone ID
	_is_az "$1" || return 1
	# get region
	if [[ $1 = *[0-9][a-z] ]]; then
		# "us-west-1a" to "us-west-1"
		echo "${1%%[a-z]}"
		return 0
	fi
	if [[ $1 = *-[a-z] ]]; then
		# "cn-beijing-b" to "cn-beijing"
		echo "${1%%-[a-z]}"
		return 0
	fi
	return 1
}

function az_to_vsw() {
	# Get default VSwitch ID by Zone ID
	_is_az "$1" || return 1
	x=$(aliyun ecs DescribeVSwitches --IsDefault true \
		--RegionId $(az_to_region "$1") --ZoneId "$1")
	[ $? = 0 ] || return 1
	echo $x | jq -r '.VSwitches.VSwitch[0].VSwitchId'
}

function az_to_vpc() {
	# Get default VPC ID by Zone ID
	_is_az "$1" || return 1
	x=$(aliyun ecs DescribeVSwitches --IsDefault true \
		--RegionId $(az_to_region "$1") --ZoneId "$1")
	[ $? = 0 ] || return 1
	echo $x | jq -r '.VSwitches.VSwitch[0].VpcId'
}

function az_to_sg() {
	# Get default VPC's Security Group ID by Zone ID
	_is_az "$1" || return 1
	x=$(aliyun ecs DescribeSecurityGroups --RegionId $(az_to_region "$1") \
		--VpcId $(az_to_vpc "$1"))
	[ $? = 0 ] || return 1
	echo $x | jq -r '.SecurityGroups.SecurityGroup[0].SecurityGroupId'
}
