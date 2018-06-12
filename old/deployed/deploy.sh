#!/bin/bash
source ~/stackrc 
echo "Use poll.sh after the deployment starts"

time openstack overcloud deploy \
	  --templates ~/templates \
	  --disable-validations \
          --libvirt-type qemu \
	  -r ~/tht/roles_data.yaml \
	  -e ~/templates/environments/deployed-server-environment.yaml \
	  -e ~/templates/environments/deployed-server-bootstrap-environment-centos.yaml \
	  -e ~/templates/environments/low-memory-usage.yaml \
	  -e ~/templates/environments/disable-telemetry.yaml \
	  -e ~/templates/environments/docker.yaml \
	  -e ~/templates/environments/ceph-ansible/ceph-ansible-external.yaml \
          -e ~/docker_registry.yaml \
	  -e ~/tht/ctlplane-assignments.yaml \
	  -e ~/tht/ceph-external.yaml

