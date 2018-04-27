#!/usr/bin/env bash
# Filename:                master.sh
# Description:             Sets up my dev env
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2018-04-27 15:02:36 fultonj> 
# -------------------------------------------------------
SCRIPT=1
FEDORA=0
RUNQ=1
PKGS=1
DISK=0
IMG=1
SCRIPTS=1
LOCAL=0
# -------------------------------------------------------
export VIRTHOST=$(hostname)

echo "Testing virthost connection"
ssh root@$VIRTHOST uname -a || (echo "ssh connection to virthost not ready" && exit 1)
# https://docs.openstack.org/tripleo-quickstart/latest/readme.html#tripleo-quickstart

if [ $SCRIPT -eq 1 ]; then
    url=https://raw.githubusercontent.com/openstack/tripleo-quickstart/master/quickstart.sh
    curl $url > quickstart.sh
    sudo rm -rf ~/.quickstart
    bash quickstart.sh --install-deps
fi

if [ $FEDORA -eq 1 ]; then
    # if [[ $(grep Fedora /etc/redhat-release) ]]; then
    echo "Workarounds are required for Fedora..."
    echo "Comment out this task: https://bit.ly/2I3ZEUG"

    echo "Ensure undercloud can ssh into hypervisor for virtual BMC"
    sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.23.0/24" port port="22" protocol="tcp" accept'
    sudo firewall-cmd --list-all-zones  | grep -A 15 active
fi

if [ $RUNQ -eq 1 ]; then
    release=master-tripleo-ci
    #release=pike
    #release=ocata
    teardown=all
    #teardown=nodes
    bash quickstart.sh -e supported_distro_check=false --teardown $teardown --release $release --skip-tags tripleoui-validate -e @q1q2.yml -c undercloud-conf.yaml $VIRTHOST
fi

if [ -d ~/.quickstart/ ]; then
    export SSH_ENV=~/.quickstart/ssh.config.ansible
fi

ssh -F $SSH_ENV stack@undercloud || (echo "No ssh for stack@undercloud; exiting."; exit 1)

if [ $PKGS -eq 1 ]; then
    # bash pkgs.sh
    if [ -d pkgs ]; then
	scp -r -F $SSH_ENV pkgs stack@undercloud:/home/stack/pkgs
	ssh -F $SSH_ENV stack@undercloud "pushd ~/pkgs ; sudo yum localinstall *.rpm -y ; popd"
	ssh -F $SSH_ENV stack@undercloud "sudo yum install -y emacs-nox vim screen"
    else
	echo "no local pkgs directory to install on undercloud"
    fi
fi

if [ $DISK -eq 1 ]; then
    # shouldn't be necessary now the tripleo-quickstart supports something like it
    bash run-add-disks.sh
fi

if [ $IMG -eq 1 ]; then
    # use to avoid ssh hangs
    bash overcloud-image-tweak.sh
fi

if [ $SCRIPTS -eq 1 ]; then
    # make it easy to pull this repo and others to the underlcoud
    ssh -F $SSH_ENV stack@undercloud "echo 'git clone git@github.com:fultonj/oooq.git ; ln   -s oooq/tht' >> sh_me"
    ssh -F $SSH_ENV stack@undercloud "echo 'git clone git@github.com:fultonj/tripleo-ceph-ansible.git '>> sh_me"
    ssh -F $SSH_ENV stack@undercloud "echo 'git clone https://github.com/yoshiki/yaml-mode.git '>> sh_me"
    # set default to source stackrc
    ssh -F $SSH_ENV stack@undercloud "echo 'source /home/stack/stackrc' >> ~/.bashrc"
    ssh -F $SSH_ENV stack@undercloud "echo 'alias os=openstack' >> ~/.bashrc"    
fi

if [ $LOCAL -eq 1 ]; then
    # this is only for when I develop on my laptop
    if [ -f ~/.ssh/id_rsa.pub ]; then
	# install my personal key on undercloud using key provided by quickstart
	scp -F $SSH_ENV cat ~/.ssh/id_rsa.pub stack@undercloud:/home/stack/
	ssh -F $SSH_ENV stack@undercloud "cat ~/id_rsa.pub >> ~/.ssh/authorized_keys"
    else
	# set a known password for the stack user
	ssh -F $SSH_ENV stack@undercloud "sudo su -c \"echo abc123 | passwd --stdin stack\""
    fi
    
    # get local simple IP that either the local emacs tramp OR tunnel.sh can reach
    ip=$(ssh -F $SSH_ENV stack@undercloud "/sbin/ip a | grep 192.168.23" | awk {'print $2'} | sed s/\\/24//g)
    if [ -f ~/.emacs ]; then
	# update tramp entry (assuming my .emacs only talks to 192.168.23.0/24 for underlap)
	echo "updating local ~/.emacs"
	sed -i -e s/192.168.23.[0-9]*/$ip/g ~/.emacs
    else
	echo "Undercloud IP for tunnel.sh is $ip"
    fi

    echo "Configuring SSH on undercloud to not warn about unknown hosts"
    ssh -F $SSH_ENV stack@undercloud "cat /dev/null > ~/.ssh/config ; echo StrictHostKeyChecking\ no >> ~/.ssh/config ; echo UserKnownHostsFile=/dev/null >> ~/.ssh/config ; echo LogLevel\ ERROR >> ~/.ssh/config ; chmod 0600 ~/.ssh/config ; chmod 0700 ~/.ssh/"
fi
