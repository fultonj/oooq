#!/usr/bin/env bash

DNS=0
IRONIC=0
CEPH_ANSIBLE=0
POST_DEPLOY=1

source ~/stackrc

# use the pre-built images coming from the tripleoupstream registry
openstack overcloud container image upload

if [ $DNS -eq 1 ]; then
    neutron subnet-list
    SNET=$(neutron subnet-list | awk '/192/ {print $2}')
    neutron subnet-show $SNET
    neutron subnet-update ${SNET} --dns-nameserver 10.19.143.247 --dns-nameserver 10.19.143.248 
    neutron subnet-show $SNET
fi

if [ $IRONIC -eq 1 ]; then
    echo "Updating ironic nodes with compute and control profiles for their respective flavors"
    ironic node-update ceph-0 replace properties/capabilities=profile:compute,boot_option:local
    ironic node-update control-0 replace properties/capabilities=profile:control,boot_option:local
fi

if [ $CEPH_ANSIBLE -eq 1 ]; then
    curl https://raw.githubusercontent.com/fultonj/tripleo-ceph-ansible/master/install-ceph-ansible.sh > install-ceph-ansible.sh
    bash install-ceph-ansible.sh
    cp -r /usr/share/ceph-ansible/ ~/ceph-ansible/
    curl https://raw.githubusercontent.com/fultonj/tripleo-ceph-ansible/master/group_vars/docker-all.yml > docker-all.yml
    mv docker-all.yml ~/ceph-ansible/group_vars/all.yml
    cp ~/ceph-ansible/site.yml.sample ~/ceph-ansible/site.yml
     # see: https://github.com/ansible/ansible/issues/11536
fi

if [ $POST_DEPLOY -eq 1 ]; then
    curl https://raw.githubusercontent.com/fultonj/tripleo-ceph-ansible/master/ansible-inventory.sh > ansible-inventory.sh
    bash ansible-inventory.sh
    ansible osds -b -m shell -a "for d in `echo /dev/vd{b,c,d}`; do sgdisk -Z \$d; sgdisk -g \$d; done; partprobe"
    echo "cd ceph-ansbile; ansible-playbook site.yml.sample"
fi
