#!/usr/bin/env bash
# Filename:                master.sh
# Description:             Sets up my dev env
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-01-11 13:29:58 jfulton> 
# -------------------------------------------------------
CLONEQ=0
RUNQ=0
DISK=0
IMG=0
SCRIPTS=0
LOCAL=1
# -------------------------------------------------------
export SSH_ENV=~/.quickstart/ssh.config.ansible
export VIRTHOST=$(hostname)

if [ $CLONEQ -eq 1 ]; then
    rm -rf tripleo-quickstart/ 2> /dev/null
    git clone https://github.com/openstack/tripleo-quickstart
    ln -s tripleo-quickstart/quickstart.sh 
fi    

if [ $RUNQ -eq 1 ]; then
    bash quickstart.sh -e supported_distro_check=false --teardown all --release master-tripleo-ci -e @myconfigfile.yml $VIRTHOST    
fi

if [ $DISK -eq 1 ]; then
    bash run-add-disks.sh
fi

if [ $IMG -eq 1 ]; then
    bash overcloud-image-tweak.sh
fi

if [ $SCRIPTS -eq 1 ]; then
    tar cvfz scripts.tar.gz git-init.sh deploy.sh dns.sh ironic.sh ironic-assign.sh wtf tht/
    scp -F $SSH_ENV scripts.tar.gz stack@undercloud:/home/stack/
    ssh -F $SSH_ENV stack@undercloud "tar xf scripts.tar.gz"
    ssh -F $SSH_ENV stack@undercloud "echo 'source /home/stack/stackrc' >> ~/.bashrc"
fi

if [ $LOCAL -eq 1 ]; then
    # install my personal key on undercloud using key provided by quickstart
    scp -F $SSH_ENV cat ~/.ssh/id_rsa.pub stack@undercloud:/home/stack/
    ssh -F $SSH_ENV stack@undercloud "cat ~/id_rsa.pub >> ~/.ssh/authorized_keys"
    # get local simple IP that my emacs tramp can reach
    ip=$(ssh -F $SSH_ENV stack@undercloud "/sbin/ip a | grep 192.168.23" | awk {'print $2'} | sed s/\\/24//g)
    # update my tramp entry (assuming my .emacs only talks to 23 for underlap)
    sed -i -e s/192.168.23.[0-9]*/$ip/g ~/.emacs
fi
