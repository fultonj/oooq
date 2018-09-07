#!/usr/bin/env bash
# speed up this process:
# https://docs.openstack.org/tripleo-docs/latest/install/advanced_deployment/ansible_config_download.html#tags

source ~/stackrc

DIR=/var/lib/mistral/overcloud

if [[ ! -e $DIR ]]; then
    echo "$DIR does not exist"
    exit 1
fi

sudo setfacl -R -m u:$USER:rwx /var/lib/mistral
pushd $DIR
ls -l external_deploy_steps_tasks.yaml
bash ansible-playbook-command.sh --tags external_deploy_steps


