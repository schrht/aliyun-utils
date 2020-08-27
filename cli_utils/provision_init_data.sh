#!/bin/bash

function update() {
	# Usage: update <key> <value>
	sed -i "s/{{ $1 }}/$2/g" $file
}

codepath=$(dirname $(which $0))
source $codepath/cli_utils.sh

file=/tmp/alibaba_common.yaml.$$

echo >$file \
	'Cloud:
    provider: alibaba
Credential:
    access_key_id: {{ access_key_id }}
    secretaccess_key: {{ secretaccess_key }}
Subscription:
    username:
    password:
VM:
    rhel_ver: "{{ rhel_ver }}"
    username: {{ username }}
    password: {{ password }}
    keypair: {{ keypair }}
    vm_name: "{{ prefix }}-instance-{{ suffix }}"
    az: {{ az_id }}
    region: {{ region_id }}
Image:
    name: {{ image_name }}
    id: {{ image_id }}
Network:
    VSwitch:
        id: {{ vsw_id }}
SecurityGroup:
    id: {{ sg_id }}
Disk:
    cloud_disk_count: 16
    cloud_disk_name: "{{ prefix }}-disk-{{ suffix }}"
    cloud_disk_size: 100
NIC:
    nic_name: "{{ prefix }}-nic-{{ suffix }}"'

# Get key id and secret
key_id=$(grep aliyun_access_key_id $HOME/.aliyuncli/credentials | sed 's/.*=\s*\(\w\)/\1/')
key_secret=$(grep aliyun_access_key_secret $HOME/.aliyuncli/credentials | sed 's/.*=\s*\(\w\)/\1/')

# Update profile
update access_key_id $key_id
update secretaccess_key $key_secret

update keypair cheshi-docker

# Update the target file
mv -f ./alibaba_common.yaml ./alibaba_common.yaml.bak
mv $file ./alibaba_common.yaml

exit 0
