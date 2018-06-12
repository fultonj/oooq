#!/usr/bin/env bash
# Filename:                ad_hoc_last_run.sh
# Time-stamp:              <2018-02-22 11:55:16 fultonj> 
# -------------------------------------------------------
# Based on latest --config-download deployment of tripleo
# make it easy to quickly run ad hoc ansible commands
# in the directory where the playbooks will run.
# -------------------------------------------------------
# tripleo-config-download --output-dir $dir
# ./ansible-playbook-command.sh --list-tags
# -------------------------------------------------------
name=$(date +%a-%I%M%p)
target=/var/lib/mistral/$(sudo ls -tr /var/lib/mistral/ | tail -1)
if [[ $(id stack | grep mistral | wc -l) -eq 0 ]]; then
    sudo usermod -a -G mistral stack
fi
if [[ $(getfacl -p $target | grep stack | wc -l ) -eq 0 ]]; then
    sudo setfacl -Rm u:stack:rwX $target
fi
ln -s $target $name
tripleo-ansible-inventory --static-yaml-inventory $name/inventory.yaml
ansible -i $name/inventory.yaml all -m ping
echo "pushd $name"
echo 'ansible -i inventory.yaml all -m shell -b -a "hostname"'
