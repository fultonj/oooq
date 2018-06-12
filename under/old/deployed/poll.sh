#!/bin/bash

source ~/stackrc 
export OVERCLOUD_ROLES="Controller"
export Controller_hosts="192.168.2.2"
~/templates/deployed-server/scripts/get-occ-config.sh

OVER=$Controller_hosts
ssh $OVER -l stack "sudo ls -lhtr /var/lib/heat-config/heat-config-script/"
