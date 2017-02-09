source ~/stackrc
pushd ~ ; upload-puppet-modules -d puppet-modules ; popd
time openstack overcloud deploy --templates ~/templates \
--libvirt-type qemu \
-e /home/stack/templates/environments/puppet-ceph-external.yaml \
-e ~/tht/external-ceph.yaml \
-e ~/tht/mistral-ceph-layout.yaml

# this script could then be updated to run:
#https://github.com/fultonj/mistral/blob/master/mistral-ceph-ansible/mistral-ceph-ansible.sh
