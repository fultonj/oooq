source ~/stackrc
pushd ~ ; upload-puppet-modules -d puppet-modules ; popd
time openstack overcloud deploy --templates ~/templates \
-r ~/tht/custom-roles.yaml \
-e /home/stack/templates/environments/storage-environment.yaml \
-e ~/tht/ceph.yaml \
-e ~/tht/layout.yaml
