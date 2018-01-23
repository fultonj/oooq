#!/bin/bash

source ~/stackrc 
export OVERCLOUD_ROLES="Controller"
export Controller_hosts="192.168.2.2"
~/templates/deployed-server/scripts/get-occ-config.sh
