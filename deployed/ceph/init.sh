#!/bin/bash

export ANSIBLE_NOCOWS=1

git clone https://github.com/ceph/ceph-ansible.git

cp group_vars/* ceph-ansible/group_vars/
cp ceph-ansible/site.yml.sample ceph-ansible/site.yml

echo "Is inventory good?"
ansible mgrs -m ping
ansible mons -m ping
ansible osds -m ping

