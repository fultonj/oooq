source ~/stackrc
pushd ~ ; upload-puppet-modules -d puppet-modules ; popd
time openstack overcloud deploy --templates ~/templates \
--stack ceph \
--libvirt-type qemu \
-e ~/tht/ceph-only.yaml
