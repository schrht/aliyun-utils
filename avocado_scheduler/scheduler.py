#!/usr/bin/env python
"""
Schedule containerized avocado-cloud tests for Alibaba Cloud.
"""

import argparse
import logging
import json
import yaml
import pandas as pd

LOG = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG, format='%(levelname)s: %(message)s')

ARG_PARSER = argparse.ArgumentParser(description="Schedule containerized \
avocado-cloud tests for Alibaba Cloud.")
ARG_PARSER.add_argument('--config',
                        dest='config',
                        action='store',
                        help='The yaml configure file for the scheduler.',
                        default='scheduler.yaml',
                        required=False)
ARG_PARSER.add_argument('--flavors',
                        dest='flavors',
                        action='store',
                        help='The flavor list for testing. (This argument \
will overwrite the one in config file)',
                        default=None,
                        required=False)
ARG_PARSER.add_argument('--containers',
                        dest='containers',
                        action='store',
                        help='The container names to perform the testing. \
(This argument will overwrite the one in config file)',
                        default=None,
                        required=False)

ARGS = ARG_PARSER.parse_args()


class AvocadoScheduler():
    """Schedule containerized avocado-cloud tests for Alibaba Cloud."""

    def __init__(self, ARGS):
        # Load config
        with open(ARGS.config, 'r') as f:
            self.config = yaml.safe_load(f)

        # Parse container names
        container_names = ARGS.containers or self.config.get('containers')
        if isinstance(container_names, str):
            self.container_names = container_names.split(' ')
        elif isinstance(container_names, list):
            self.container_names = container_names
        else:
            logging.error('Can not get CONTAINERS.')
            exit(1)

        # Parse flavors
        flavors = ARGS.flavors or self.config.get('flavors')
        if isinstance(flavors, str):
            self.flavors = flavors.split(' ')
        elif isinstance(flavors, list):
            self.flavors = flavors
        else:
            logging.error('Can not get FLAVORS.')
            exit(1)

        return None

    def show_vars(self):
        """Print the varibles to the stdout."""
        def _show(name, value):
            print('\n> _show(%s):\n' % name)
            print(value)

        _show('self.config', self.config)
        _show('self.container_names', self.container_names)
        _show('self.flavors', self.flavors)


if __name__ == '__main__':
    scheduler = AvocadoScheduler(ARGS)
    scheduler.show_vars()

exit(0)
