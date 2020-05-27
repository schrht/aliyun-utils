#!/usr/bin/env python

import argparse
import os
import re
import configparser
import hashlib
import random

ARG_PARSER = argparse.ArgumentParser(
    description="Run tests for Alibaba Cloud.")

ARG_PARSER.add_argument('--cname',
                        dest='cname',
                        action='store',
                        help="container name for executing avocado_cloud",
                        default='acx',
                        required=False)

ARG_PARSER.add_argument(
    '--image',
    dest='image',
    action='store',
    help="specify aliyun image for testing",
    default='redhat_7_8_x64_20G_alibase_20200522_copied.qcow2',
    required=False)

ARG_PARSER.add_argument('--flavor',
                        dest='flavor',
                        action='store',
                        help="specify aliyun flavor (instance type)",
                        default='ecs.i2.xlarge',
                        required=False)

ARG_PARSER.add_argument('--az',
                        dest='az',
                        action='store',
                        help="specify availability zone for testing",
                        default='cn-huhehaote-a',
                        required=False)


class Provisioner(object):

    datapath = os.path.join(os.path.expanduser('~'), ".datapath")
    common = {"path": os.path.join(datapath, "alibaba_common.yaml")}
    flavors = {"path": os.path.join(datapath, "alibaba_flavors.yaml")}
    testcases = {"path": os.path.join(datapath, "alibaba_testcases.yaml")}

    common["content"] = """\
Cloud:
    provider: alibaba
Credential:
    access_key_id: %(access_key_id)s
    secretaccess_key: %(access_key_secret)s
VM:
    rhel_ver: %(rhel_ver)s
    username: %(username)s
    password: %(password)s
    keypair: %(keypair)s
    vm_name: %(vm_name)s
    az: %(az)s
    region: %(region)s
Image:
    name: %(image_name)s
    id: %(image_id)s
Network:
    VSwitch:
        id: %(vsw_id)s
SecurityGroup:
    id: %(sg_id)s
Disk:
    cloud_disk_count: 16
    cloud_disk_name: %(cloud_disk_name)s
    cloud_disk_size: 100
NIC:
    nic_name: %(nic_name)s
"""

    flavors["content"] = """\
%(flavors_content)s
"""

    testcases["content"] = """\
%(testcases_content)s
"""

    access_key_id = None
    access_key_secret = None
    rhel_ver = None
    username = None
    password = None
    keypair = None
    vm_name = None
    az = None
    region = None
    image_name = None
    image_id = None
    vsw_id = None
    sg_id = None
    cloud_disk_name = None
    nic_name = None
    flavors_content = None
    testcases_content = None
    label = None

    def __init__(self,
                 label=None,
                 access_key_id=None,
                 access_key_secret=None,
                 rhel_ver=None,
                 username=None,
                 password=None,
                 keypair=None,
                 az=None,
                 image_name=None,
                 flavors=None):

        if not os.path.isdir(self.datapath):
            os.makedirs(self.datapath, 0o755)

        self.label = label
        self.rhel_ver = rhel_ver
        self.username = username
        self.keypair = keypair
        self.az = az
        self.image_name = image_name

        # get password
        if password is not None:
            self.password = password
        else:
            self.password = hashlib.md5(str(
                random.random()).encode()).hexdigest()

        # get credentials
        if access_key_id is not None and access_key_secret is not None:
            self.access_key_id = access_key_id
            self.access_key_secret = access_key_secret
        else:
            cfgfile = os.path.join(os.path.expanduser('~'), '.aliyuncli',
                                   'credentials')
            cfg = configparser.ConfigParser()
            cfg.read(cfgfile)
            self.access_key_id = cfg.get('default', 'aliyun_access_key_id')
            self.access_key_secret = cfg.get('default',
                                             'aliyun_access_key_secret')

        # get region
        p = re.compile(r".*-[a-z]$")
        if p.match(az):
            self.region = az[:-2]
        else:
            self.region = az[:-1]

        # set resource name
        self.vm_name = 'automation-inst-{0}'.format(label)
        self.cloud_disk_name = 'automation-disk-{0}'.format(label)
        self.nic_name = 'automation-nic-{0}'.format(label)

        # lookup network
        self.vsw_id = 'vsw-hp3692vfy9ed3nozu86sn'
        self.sg_id = 'sg-hp3ftqi34pgcdg5c30cv'

        # lookup image_id
        self.image_id = 'm-hp3e8rl53kkoa9nsv1yf'

    def _write_file(self, dfile):
        with open(dfile["path"], 'w') as f:
            f.write(dfile["content"] % self.config)

    def _lookup(self):
        # get region
        p = re.compile(r".*-[a-z]$")
        if p.match(self.az):
            self.region = self.az[:-2]
        else:
            self.region = self.az[:-1]

        # set resource name
        self.vm_name = 'automation-inst-{0}'.format(self.label)
        self.cloud_disk_name = 'automation-disk-{0}'.format(self.label)
        self.nic_name = 'automation-nic-{0}'.format(self.label)

        # lookup network
        self.vsw_id = 'vsw-hp3692vfy9ed3nozu86sn'
        self.sg_id = 'sg-hp3ftqi34pgcdg5c30cv'

        # lookup image_id
        self.image_id = 'm-hp3e8rl53kkoa9nsv1yf'

    def update(self):
        self.config = dict()
        self.config["access_key_id"] = self.access_key_id
        self.config["access_key_secret"] = self.access_key_secret
        self.config["rhel_ver"] = self.rhel_ver
        self.config["username"] = self.username
        self.config["password"] = self.password
        self.config["keypair"] = self.keypair
        self.config["vm_name"] = self.vm_name
        self.config["az"] = self.az
        self.config["region"] = self.region
        self.config["image_name"] = self.image_name
        self.config["image_id"] = self.image_id
        self.config["vsw_id"] = self.vsw_id
        self.config["sg_id"] = self.sg_id
        self.config["cloud_disk_name"] = self.cloud_disk_name
        self.config["nic_name"] = self.nic_name
        self.config["flavors_content"] = self.flavors_content
        self.config["testcases_content"] = self.testcases_content

        self._write_file(self.common)
        # self._write_file(self.flavors)
        # self._write_file(self.testcases)
        print("Update test data finished.")


def gather_parms():

    ARGS = ARG_PARSER.parse_args()
    print(ARGS.az)


def provision():

    Provisioner(
        access_key_id=None,
        access_key_secret=None,
        rhel_ver=None,
        username=None,
        password=None,
        keypair=None,
        vm_name=None,
        az=None,
        region=None,
        image_name=None,
        image_id=None,
        vsw_id=None,
        sg_id=None,
        cloud_disk_name=None,
        nic_name=None,
        flavors_content=None,
        testcases_content=None,
    ).update()


if __name__ == '__main__':
    p = Provisioner(label='acx',
                    access_key_id='aaa',
                    access_key_secret='bbb',
                    rhel_ver='7.8',
                    username='cheshi',
                    password='abc',
                    keypair='cheshi-docker',
                    az='cn-huhehaote-b',
                    image_name='m-abcde',
                    flavors='ecs.i2.xlarge')
    p.update()
    pass
