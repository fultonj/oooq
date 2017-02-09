source ~/stackrc
pushd ~ ; upload-puppet-modules -d puppet-modules ; popd
time openstack overcloud deploy --templates ~/templates \
--libvirt-type qemu \
-r ~/tht/custom-roles.yaml \
-e /home/stack/templates/environments/storage-environment.yaml \
-e ~/tht/ceph.yaml \
-e ~/tht/hci-layout.yaml
