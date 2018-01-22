source ~/stackrc
pushd ~ ; upload-puppet-modules -d puppet-modules ; popd
time openstack overcloud deploy --templates ~/templates \
--libvirt-type qemu \
-r ~/tht/roles_data.yaml \
-e /home/stack/templates/environments/docker.yaml \
-e /home/stack/templates/environments/puppet-ceph-external.yaml \
-e ~/tht/external-ceph.yaml \
-e ~/tht/container-overcloud-ext-layout.yaml
