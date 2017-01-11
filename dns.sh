#!/usr/bin/env bash
# Filename:                ironic-dns.sh
# Description:             Set DNS for undercloud 
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-01-11 10:17:19 jfulton> 
# -------------------------------------------------------
source ~/stackrc
echo "Setting DNS Server"
neutron subnet-list
SNET=$(neutron subnet-list | awk '/192/ {print $2}')
neutron subnet-show $SNET
neutron subnet-update ${SNET} --dns-nameserver 192.168.24.1 --dns-nameserver 192.168.1.1
neutron subnet-show $SNET
