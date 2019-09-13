#!/usr/bin/env bash

source ~/stackrc

MON_IP=192.168.24.13
CephClusterFSID=$(ssh heat-admin@$MON_IP "grep -i fsid /etc/ceph/ceph.conf" | awk 'BEGIN { FS = " = " } ; { print $2 }')
CephClientKey=$(ssh heat-admin@$MON_IP "sudo grep key /etc/ceph/ceph.client.openstack.keyring" | awk 'BEGIN { FS = " = " } ; { print $2 }')

# assumes compute node has >= 4096 MB of RAM or a modified compute flavor
cat <<EOF > $HOME/external_ceph.yaml
parameter_defaults:
  CephClusterFSID: "$CephClusterFSID"
  CephClientKey: "$CephClientKey"
  CephExternalMonHost: "$MON_IP"
  ControllerCount: 1
  ComputeCount: 1
  OvercloudControlFlavor: control
  OvercloudComputeFlavor: compute
EOF

time openstack overcloud deploy --templates ~/templates \
	  -e ~/templates/environments/ceph-ansible/ceph-ansible-external.yaml \
	  -e ~/external_ceph.yaml
