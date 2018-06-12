#!/usr/bin/env bash

HEAT=1
DOWN=1
CONF=1

source ~/stackrc

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates templates
fi

if [[ $HEAT -eq 1 ]]; then
    time openstack overcloud deploy \
	 --templates ~/templates/ \
	 --libvirt-type qemu \
	 -e ~/cloud-names.yaml \
	 -e ~/templates/environments/docker.yaml \
	 -e ~/templates/environments/docker-ha.yaml \
	 -e ~/docker_registry.yaml \
         -e ~/templates/environments/network-isolation.yaml \
	 -e ~/templates/environments/net-single-nic-with-vlans.yaml \
	 -e ~/network-environment.yaml \
	 -e ~/templates/environments/low-memory-usage.yaml \
	 -e ~/templates/environments/disable-telemetry.yaml \
	 -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
	 -e ~/overrides.yaml \
	 --no-config-download
    # remove --no-config-download to make DOWN and CONF unnecessary
fi
# -------------------------------------------------------
if [[ $DOWN -eq 1 ]]; then
    if [[ $(openstack stack list | grep overcloud | wc -l) -eq 0 ]]; then
	echo "No overcloud heat stack. Exiting"
	exit 1
    fi
    tripleo-config-download
    if [[ ! -d tripleo-config-download ]]; then
	echo "tripleo-config-download cmd didn't create tripleo-config-download dir"
    else
	pushd tripleo-config-download
	tripleo-ansible-inventory --static-yaml-inventory inventory.yaml
	ansible --ssh-extra-args "-o StrictHostKeyChecking=no" -i inventory.yaml all -m ping
	popd
	echo "pushd tripleo-config-download"
	echo 'ansible -i inventory.yaml all -m shell -b -a "hostname"'
    fi
fi
# -------------------------------------------------------
if [[ $CONF -eq 1 ]]; then
    if [[ ! -e tripleo-config-download/deploy_steps_playbook.yaml ]]; then
	MOST_RECENT_DIR=$(ls -trF tripleo-config-download | grep / | tail -1)
    fi
    time ansible-playbook \
	 -v \
	 --ssh-extra-args "-o StrictHostKeyChecking=no" --timeout 240 \
	 --become \
	 -i tripleo-config-download/inventory.yaml \
	 tripleo-config-download/$MOST_RECENT_DIR/deploy_steps_playbook.yaml
fi
