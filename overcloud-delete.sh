#!/usr/bin/env bash

source ~/stackrc
if [[ $(openstack stack list | grep overcloud) ]]
then
    echo "Deleting overcloud"
    openstack stack delete overcloud --yes --wait
else
    echo "There is no overcloud to delete"
    openstack stack list
fi
#echo "Deleting Swift Container of overcloud Heat templates"
#openstack overcloud plan delete overcloud 
# fixme: the above shouldn't be necessary as the plan should be deleted

echo "checking on node cleaning"
openstack baremetal node list | grep clean 

echo "The following node(s) have clean failed status"
echo "Following https://docs.openstack.org/ironic/latest/admin/cleaning.html"

for node_ident in $(openstack baremetal node list | grep "clean failed" | awk {'print $2'});
do
    echo "moving $node_ident to manageable state"
    openstack baremetal node manage $node_ident

    echo "moving $node_ident out of maintenance mode"    
    openstack baremetal node maintenance unset $node_ident

    echo "marking $node_ident as available for scheduling by nova"
    openstack baremetal node provide $node_ident
    
    echo "node $node_ident should now attempt cleaning again"
    openstack baremetal node list | grep clean | grep $node_ident
done

echo "Re-checking on node cleaning"
openstack baremetal node list | grep clean 

echo "Checking for uncleaned swift container"
if [[ $(grep OS_AUTH_URL ~/stackrc | grep v3) ]]; then
    echo "Removing overcloud-swift-rings (assuming bug not yet resolved)"
    swift delete overcloud-swift-rings
else
    echo "Unable to authenticate to swift add 'v3' to end of the following:"
    grep OS_AUTH_URL ~/stackrc | grep -v export
fi
