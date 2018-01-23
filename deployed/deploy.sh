#!/bin/bash
source ~/stackrc 
echo "Use poll.sh after the deployment starts"

openstack overcloud deploy \
	  --templates ~/templates \
	  --disable-validations \
	  -r ~/tht/roles_data.yaml \
	  -e ~/templates/environments/deployed-server-environment.yaml \
	  -e ~/templates/environments/deployed-server-bootstrap-environment-centos.yaml \
	  -e ~/tht/ctlplane-assignments.yaml

# -e ~/templates/environments/deployed-server-pacemaker-environment.yaml \
