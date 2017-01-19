#!/usr/bin/env bash

source ~/stackrc
if [[ $(openstack stack list | grep overcloud) ]]
then
    echo "Deleting overcloud"
    openstack stack delete overcloud --yes
    # fixme: adding --wait above should make the loop below unnecessary
    echo "Waiting for stack to be removed and hosts to shutdown."
    while [[ $(openstack stack list | grep overcloud) ]]
    do
	echo -n ".."
	sleep 2	
    done
    echo ".. deleted" 
else
    echo "There is no overcloud to delete"
    openstack stack list
fi
echo "Deleting Swift Container of overcloud Heat templates"
openstack overcloud plan delete overcloud 
# fixme: the above shouldn't be necessary as the plan should be deleted
