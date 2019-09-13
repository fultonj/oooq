#!/usr/bin/env bash

# deploy one-node all-in-one ceph cluster w/ tripleo
source ~/stackrc

CAP=$(openstack baremetal node show -f json -c properties ceph-0 \
          | jq '.properties.capabilities')
if [[ $CAP != '"profile:ceph-storage,boot_option:local"' ]]; then
    openstack baremetal node set \
          --property "capabilities=profile:ceph-storage,boot_option:local" \
          ceph-0
fi

cat <<EOF > $HOME/just_ceph.yaml
parameter_defaults:
  ControllerCount: 0
  ComputeCount: 0
  CephAllCount: 1
  OvercloudCephAllFlavor: ceph-storage
  CephAnsiblePlaybookVerbosity: 1
  CephAnsibleEnvironmentVariables:
    ANSIBLE_SSH_RETRIES: '6'
  CephPoolDefaultSize: 1
  CephPoolDefaultPgNum: 32
  CephAnsiblePlaybook: /usr/share/ceph-ansible/site-docker.yml.sample
  CephAnsibleDisksConfig:
    devices:
      - /dev/vdb
      - /dev/vdc
      - /dev/vdd
    journal_size: 5120
  CephAnsibleExtraConfig:
    osd_scenario: collocated
    osd_objectstore: filestore
    ceph_osd_docker_memory_limit: 5g
    ceph_osd_docker_cpu_limit: 1
  CephConfigOverrides:
    osd_recovery_op_priority: 3
    osd_recovery_max_active: 3
    osd_max_backfills: 1
EOF

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

openstack overcloud deploy --templates ~/templates --stack ceph \
	  -r ~/templates/roles/CephAll.yaml \
	  -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
          -e ~/just_ceph.yaml
