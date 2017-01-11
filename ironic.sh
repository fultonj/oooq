#!/usr/bin/env bash
# Filename:                ironic.sh
# Description:             ironic node import and set dns 
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-01-11 14:58:33 jfulton> 
# -------------------------------------------------------
DELETE=0
INSPECT=1
TAG_HCI=1
# -------------------------------------------------------
source ~/stackrc

if [ $DELETE -eq 1 ]; then
    # delete all ironic nodes, including ones described in: 
    #  http://blog.johnlikesopenstack.com/2016/08/ironic-node-clinging-to-nova-instance.html
    ironic node-list | grep  "power off" | awk {'print $6'} | grep -v "None" > /tmp/ironic_nova_zombies
    if [[ $(wc -l /tmp/ironic_nova_zombies | awk {'print $1'}) -gt 0 ]]; then
	echo "Removing ironic nodes stuck to nova instances that no longer exist"
	for nova_id in $(cat /tmp/ironic_nova_zombies); do
	    ironic_id=$(ironic node-list | grep $nova_id | awk {'print $2'})
	    ironic node-set-provision-state $ironic_id manage
	    ironic node-set-maintenance $ironic_id on
	    ironic node-delete $ironic_id
	done
    fi
    echo "Removing remaining ironic nodes"
    for ironic_id in $(ironic node-list | grep  "power off" | awk {'print $2'}); do
	ironic node-delete $ironic_id
    done
    # for svc in $(systemctl list-unit-files | grep ironic | awk {'print $1'}); do
    # 	sudo systemctl restart $svc;
    # done
fi
# -------------------------------------------------------
if [ $INSPECT -eq 1 ]; then
    if [[ ! -f ~/instackenv.json ]]; then
	echo "unable to find ~/instackenv.json"
	exit 1
    fi
    echo "Importing hardware list"
    openstack baremetal import ~/instackenv.json

    echo "Assigning the kernel and ramdisk images to all nodes"
    openstack baremetal configure boot 

    echo "About to introspect the following servers"
    ironic node-list

    echo "Starting introspection. This should take 10 minutes."
    date
    time openstack baremetal introspection bulk start
    date 

    echo "The following *should* be ready for deployment"
    ironic node-list
    
    echo "Ironic node properties have been set to the following:"
    for ironic_id in $(ironic node-list | awk {'print $2'} | grep -v UUID | egrep -v '^$');
    do
	echo $ironic_id; ironic node-show $ironic_id  | egrep -A 1 "memory_mb|profile|wwn" ;
	echo "";
    done
fi
# -------------------------------------------------------
if [ $TAG_HCI -eq 1 ]; then
    ./ironic-assign.sh control-0 controller
    ./ironic-assign.sh ceph-0 osd-compute
    # put seprate compute node in maintenance mode
    ironic node-set-maintenance compute-0 on
fi
