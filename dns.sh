#!/usr/bin/env bash
# Filename:                ironic-dns.sh
# Description:             Set DNS for undercloud 
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-02-24 16:14:22 jfulton> 
# -------------------------------------------------------
source ~/stackrc
echo "Setting DNS Server"
neutron subnet-list
SNET=$(neutron subnet-list | awk '/192/ {print $2}')
neutron subnet-show $SNET
neutron subnet-update ${SNET} --dns-nameserver 192.168.23.1
neutron subnet-show $SNET
