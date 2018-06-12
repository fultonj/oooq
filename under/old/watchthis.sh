#!/bin/bash
. ~/stackrc
watch -d "openstack stack resource list overcloud -c resource_name -c resource_type -c resource_status -n2 | grep -vi complete"
