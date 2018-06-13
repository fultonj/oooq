#!/usr/bin/env bash
# -------------------------------------------------------
WORKAROUND=1
NEW_OOOQ=1
RUNQ=1
PKGS=1
SCRIPTS=1
VALIDATE=0
RELEASE=master-tripleo-ci
#RELEASE=queens
# -------------------------------------------------------
export VIRTHOST=127.0.0.2
echo "Testing virthost connection"
ssh root@$VIRTHOST uname -a || (echo "ssh connection to virthost not ready" && exit 1)
#ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
#ssh-copy-id root@127.0.0.2
# -------------------------------------------------------
if [ $WORKAROUND -eq 1 ]; then
    sudo yum install -y libguestfs-tools wget
    # Due to https://bugzilla.redhat.com/show_bug.cgi?id=1581364 libvirt issue
    mkdir rpms; pushd rpms
    wget -r -nd -l1 -v --no-parent  http://file.rdu.redhat.com/~mbaldess/libvirt-rpms/ 
    sudo yum install -y *rpm
    popd
    sudo systemctl restart libvirtd
fi
# -------------------------------------------------------
if [ $NEW_OOOQ -eq 1 ]; then
    url=https://raw.githubusercontent.com/openstack/tripleo-quickstart/master/quickstart.sh
    curl $url > quickstart.sh
    sudo rm -rf ~/.quickstart
    bash quickstart.sh --install-deps
fi
# -------------------------------------------------------
if [ $RUNQ -eq 1 ]; then
    time bash quickstart.sh \
    	 --teardown all \
    	 --release $RELEASE \
    	 --nodes nodes.yaml \
    	 --config config.yaml \
    	 $VIRTHOST

    echo "generating network config as per LP173760"
    bash quickstart.sh \
	 --teardown none \
	 --retain-inventory \
	 --tags 'overcloud-prep-config' \
	 --release $RELEASE \
	 --nodes nodes.yaml \
	 --config config.yaml \
	 $VIRTHOST
fi
# -------------------------------------------------------
if [ -d ~/.quickstart/ ]; then
    export SSH_ENV=~/.quickstart/ssh.config.ansible
fi
# -------------------------------------------------------
ssh -F $SSH_ENV stack@undercloud "uname -a" || (echo "No ssh for stack@undercloud; exiting."; exit 1)
# -------------------------------------------------------
if [ $PKGS -eq 1 ]; then
    if [ ! -d pkgs ]; then
	bash pkgs.sh # create packages directory
    fi
    if [ -d pkgs ]; then
	scp -r -F $SSH_ENV pkgs stack@undercloud:/home/stack/pkgs
	ssh -F $SSH_ENV stack@undercloud "pushd ~/pkgs ; sudo yum localinstall *.rpm -y ; popd"
	ssh -F $SSH_ENV stack@undercloud "sudo yum install -y emacs-nox vim tmux"
    else
	echo "no local pkgs directory to install on undercloud"
    fi
fi
# -------------------------------------------------------
if [ $SCRIPTS -eq 1 ]; then
    ssh -F $SSH_ENV stack@undercloud "echo 'curl https://github.com/fultonj.keys >> ~/.ssh/authorized_keys' >> sh_me"
    ssh -F $SSH_ENV stack@undercloud "echo 'ssh-keyscan github.com >> ~/.ssh/known_hosts' >> sh_me"
    ssh -F $SSH_ENV stack@undercloud "echo 'git clone git@github.com:fultonj/oooq.git' >> sh_me"
    ssh -F $SSH_ENV stack@undercloud "echo 'ln -s ~/oooq/over/deploy.sh' >> sh_me"
    ssh -F $SSH_ENV stack@undercloud "echo 'ln -s ~/oooq/over/overrides.yaml' >> sh_me"
    ssh -F $SSH_ENV stack@undercloud "echo 'source /home/stack/stackrc' >> ~/.bashrc"
    ssh -F $SSH_ENV stack@undercloud "echo 'alias os=openstack' >> ~/.bashrc"    
fi
# -------------------------------------------------------
if [ $VALIDATE -eq 1 ]; then
    bash quickstart.sh \
	 --teardown none \
	 --retain-inventory \
	 --tags 'overcloud-validate' \
	 --release $RELEASE \
	 --nodes nodes.yaml \
	 --config config.yaml \
	 $VIRTHOST
fi
