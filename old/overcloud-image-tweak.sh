#!/usr/bin/env bash
# Filename:                overcloud-image-tweak.sh
# Description:             update overcloud image from oooq
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-01-10 23:17:06 jfulton> 
# -------------------------------------------------------
SSH_ENV=~/.quickstart/ssh.config.ansible
IMAGE='overcloud-full.qcow2'
PASSWORD='abc123'

if [[ ! -f $SSH_ENV ]]; then
    echo "FAIL: $SSH_ENV is missing. Run TripleO Quickstart first."
    exit 1
fi
if [[ ! $(rpm -q libguestfs-tools) ]]; then
    echo "virt-customize is not installed. Attempting to install."
    sudo yum install libguestfs-tools -y 
fi

echo "Looking for $IMAGE on undercloud"
ssh -A -F $SSH_ENV undercloud "ls -lh ~/$IMAGE" 2> /dev/null

HAS_IMAGE=$(ssh -A -F $SSH_ENV undercloud "ls ~/$IMAGE | wc -l" 2> /dev/null)
if [[ "$HAS_IMAGE" == "0" ]]; then
    echo "FAIL: $IMAGE is not on undercloud. Run TripleO Quickstart first."
    exit 1
fi

echo "Pulling down copy of $IMAGE"
scp -F $SSH_ENV stack@undercloud:/home/stack/$IMAGE . 2> /dev/null

echo "Setting root password to $PASSWORD"
virt-customize -a $IMAGE --root-password password:$PASSWORD

echo "Updating SSH to not do reverse DNS lookup"
virt-customize -a $IMAGE --run-command "echo 'UseDNS no' >> /etc/ssh/sshd_config"

echo "Pushing up new copy of $IMAGE"
scp -F $SSH_ENV $IMAGE stack@undercloud:/home/stack/$IMAGE 2> /dev/null

echo "Deleting local copy of $IMAGE"
rm -f $IMAGE

echo "Uploading new image to Undercloud Glance"
ssh -A -F $SSH_ENV undercloud "source ~/stackrc; openstack overcloud image upload --update-existing"
