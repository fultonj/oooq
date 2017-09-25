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
