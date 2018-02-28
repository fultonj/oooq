#!/usr/bin/env bash

HEAT=1
CONF=1
PLAY=1

source ~/stackrc

if [[ $HEAT -eq 1 ]]; then
    # 13 minutes to deploy baremetal and generate config data
    # ./ironic-assign.sh ceph ceph-storage
    time openstack overcloud deploy \
	 --templates ~/templates/ \
	 --libvirt-type qemu \
	 -e ~/templates/environments/docker.yaml \
	 -e ~/templates/environments/docker-ha.yaml \
	 -e ~/docker_registry.yaml \
	 -e ~/templates/environments/low-memory-usage.yaml \
	 -e ~/templates/environments/disable-telemetry.yaml \
	 -e ~/templates/environments/config-download-environment.yaml \
	 -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
	 -e ./overrides.yaml

    # Add the following to the above to make CONF/PLAY unnecessary
    #   --config-download
fi
# -------------------------------------------------------
if [ -z "$1" ]; then
    NAME=$(date +%a-%I%M%p)
else
    NAME=$1
fi
# -------------------------------------------------------
if [[ $CONF -eq 1 ]]; then
    # 1 minute to download config data
    if [[ $(openstack stack list | grep overcloud | wc -l) -eq 0 ]]; then
	echo "No overcloud heat stack. Exiting"
	exit 1
    fi
    tripleo-config-download
    if [[ ! -d tripleo-config-download ]]; then
	echo "tripleo-config-download cmd didn't create tripleo-config-download dir"
    else
	target=tripleo-config-download/$(ls -tr tripleo-config-download | tail -1)
	ln -s $target $NAME
	tripleo-ansible-inventory --static-yaml-inventory $NAME/inventory.yaml
	ansible -i $NAME/inventory.yaml all -m ping
	echo "pushd $NAME"
	echo 'ansible -i inventory.yaml all -m shell -b -a "hostname"'
    fi
fi
# -------------------------------------------------------
if [[ $PLAY -eq 1 ]]; then
    # 18 minutes to configure _minimal_ overcloud
    time ansible-playbook \
	 -v \
	 --ssh-extra-args "-o StrictHostKeyChecking=no" --timeout 240 \
	 --become \
	 -i $NAME/inventory.yaml \
	 $NAME/deploy_steps_playbook.yaml
    #  "$@"
   
fi
