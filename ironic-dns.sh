#!/usr/bin/env bash
# Filename:                ironic-dns.sh
# Description:             ironic node import and set dns 
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-01-10 19:36:29 jfulton> 
# -------------------------------------------------------
source ~/stackrc

echo "Update instackenv.json for scheulder hints node assignment"
sed -i -e s/profile:ceph/node:osd-compute-0/g -e s/profile:control/node:controller-0/g instackenv.json 

echo "importing list of virtual hardware into ironic"
openstack baremetal import instackenv.json

echo "introspecing nodes"
openstack baremetal introspection bulk start

echo "Setting DNS Server"
neutron subnet-list
SNET=$(neutron subnet-list | awk '/192/ {print $2}')
neutron subnet-show $SNET
neutron subnet-update ${SNET} --dns-nameserver 192.168.24.1 --dns-nameserver 192.168.1.1
neutron subnet-show $SNET
