#!/usr/bin/env bash

source ~/stackrc

DIR=/var/lib/mistral/overcloud

if [[ ! -e $DIR ]]; then
    echo "$DIR does not exist"
    exit 1
fi

sudo setfacl -R -m u:$USER:rwx /var/lib/mistral
pushd $DIR
bash ansible-playbook-command.sh --tags external_deploy_steps
