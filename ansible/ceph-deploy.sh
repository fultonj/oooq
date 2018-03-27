#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "USAGE: $0 PATH"
    echo "PATH should be path to directory containing --config-download output"
    exit 1
else
    NAME=$1    
fi

if [[ ! -f $NAME/ceph-ansible/inventory.yml ]]; then
    echo "No inventory \"$NAME/ceph-ansible/inventory.yml\" found. Aborting"
    exit 1
fi

FETCH_DIR=$(mktemp)

HOME="$NAME/ceph-ansible"
ANSIBLE_LIBRARY="/usr/share/ceph-ansible/library/"
ANSIBLE_RETRY_FILES_ENABLED="False"
ANSIBLE_CONFIG="/usr/share/ceph-ansible/ansible.cfg"
ANSIBLE_LOG_PATH="/var/log/mistral/ceph-install-workflow.log"
ANSIBLE_ROLES_PATH="/usr/share/ceph-ansible/roles/"
ANSIBLE_ACTION_PLUGINS="/usr/share/ceph-ansible/plugins/actions/"
ANSIBLE_SSH_RETRIES="3"
ANSIBLE_HOST_KEY_CHECKING="False"

time ansible-playbook \
     -v \
     --ssh-extra-args "-o StrictHostKeyChecking=no" --timeout 240 \
     --become \
     --become-user root \
     -i $NAME/ceph-ansible/inventory.yml \
     --user tripleo-admin \
     --skip-tags package-install,with_pkg \
     --extra-vars "{\"fetch_directory\": \"$FETCH_DIR\"}" \
     /usr/share/ceph-ansible/site-docker.yml.sample



