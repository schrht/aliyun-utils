# Usage

## Prepare a list of flavors

➜  cat new_flavors.txt 
ecs.ebmg5.24xlarge
ecs.ic5.large
......
ecs.ebmr5s.24xlarge

## Query SPECs as json

➜  ./get_spec_json.sh 
Query Alibaba ECS SPEC and dump to a json file.
get_spec_json.sh <-f FLAVOR_LIST> <-j JSON_FILE>

➜  ./get_spec_json.sh -f "$(cat new_flavors.txt)" -j new_flavors.json

➜  head -n 2 new_flavors.json
{ "CpuCoreCount": 96, "DiskQuantity": 17, "EniIpv6AddressQuantity": 0, "EniPrivateIpAddressQuantity": 10, "EniQuantity": 32, "EniTotalQuantity": 32, "EniTrunkSupported": false, "EriQuantity": 0, "GPUAmount": 0, "GPUSpec": "", "InstanceBandwidthRx": 10240000, "InstanceBandwidthTx": 10240000, "InstanceFamilyLevel": "CreditEntryLevel", "InstancePpsRx": 4500000, "InstancePpsTx": 4500000, "InstanceTypeFamily": "ecs.ebmg5", "InstanceTypeId": "ecs.ebmg5.24xlarge", "LocalStorageCategory": "", "MemorySize": 384, "NvmeSupport": "unsupported", "PrimaryEniQueueNumber": 8, "SecondaryEniQueueNumber": 1, "TotalEniQueueQuantity": 39 }
{ "CpuCoreCount": 2, "DiskQuantity": 17, "EniIpv6AddressQuantity": 0, "EniPrivateIpAddressQuantity": 6, "EniQuantity": 2, "EniTotalQuantity": 2, "EniTrunkSupported": false, "EriQuantity": 0, "GPUAmount": 0, "GPUSpec": "", "InstanceBandwidthRx": 1024000, "InstanceBandwidthTx": 1024000, "InstanceFamilyLevel": "EnterpriseLevel", "InstancePpsRx": 300000, "InstancePpsTx": 300000, "InstanceTypeFamily": "ecs.ic5", "InstanceTypeId": "ecs.ic5.large", "LocalStorageCategory": "", "MemorySize": 2, "NvmeSupport": "unsupported", "PrimaryEniQueueNumber": 2, "SecondaryEniQueueNumber": 2, "TotalEniQueueQuantity": 4 }

## Covert json to table

➜  ./convert_spec_table.sh 
Convert Alibaba ECS SPEC json to the csv.
convert_spec_table.sh <-j JSON_FILE> <-c CSV_FILE>

➜  ./convert_spec_table.sh -j new_flavors.json -c new_flavors.csv

➜  head -n 3 new_flavors.csv
InstanceTypeId,InstanceTypeFamily,InstanceFamilyLevel,BaselineCredit,InitialCredit,CpuCoreCount,MemorySize,GPUAmount,GPUSpec,DiskQuantity,NvmeSupport,LocalStorageAmount,LocalStorageCapacity,LocalStorageCategory,EniQuantity,EniTotalQuantity,EniIpv6AddressQuantity,EniPrivateIpAddressQuantity,EniTrunkSupported,PrimaryEniQueueNumber,SecondaryEniQueueNumber,TotalEniQueueQuantity,MaximumQueueNumberPerEni,EriQuantity,InstanceBandwidthRx,InstanceBandwidthTx,InstancePpsRx,InstancePpsTx
ecs.ebmg5.24xlarge,ecs.ebmg5,CreditEntryLevel,null,null,96,384,0,,17,unsupported,null,null,,32,32,0,10,false,8,1,39,null,0,10240000,10240000,4500000,4500000
ecs.ic5.large,ecs.ic5,EnterpriseLevel,null,null,2,2,0,,17,unsupported,null,null,,2,2,0,6,false,2,2,4,null,0,1024000,1024000,300000,300000


