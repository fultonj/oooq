source ~/stackrc
time openstack overcloud deploy --templates \
-r ~/tht/custom-roles.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/storage-environment.yaml \
-e ~/tht/ceph.yaml \
-e ~/tht/layout.yaml
