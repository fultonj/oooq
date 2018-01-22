source ~/stackrc
#pushd ~ ; upload-puppet-modules -d puppet-modules ; popd
time openstack overcloud deploy --templates ~/templates \
--libvirt-type qemu \
-e /home/stack/templates/environments/docker.yaml \
-e /home/stack/templates/environments/docker-network.yaml
