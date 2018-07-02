#!/usr/bin/env bash
# -------------------------------------------------------
WORKAROUND=0
NEW_OOOQ=0
DEV=1
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
    if [ $DEV -eq 1 ]; then
	echo "ERROR: DEV is not compatible with NEW_OOOQ"
	exit 1
    fi
    sudo rm -rf ~/.quickstart
    url=https://raw.githubusercontent.com/openstack/tripleo-quickstart/master/quickstart.sh
    curl $url > quickstart.sh
    bash quickstart.sh --install-deps
fi
# -------------------------------------------------------
if [ $DEV -eq 1 ]; then
    sudo rm -rf ~/.quickstart
    # if you already set up ~/git/{tripleo-quickstart,tripleo-quickstart-extras}
    # with downloaded code reviews, then they will be used. otherwise, get them
    OOOQ_REVIEW=579381
    OOOQ_EXTRAS_REVIEW=579382
    if [ $NEW_OOOQ -eq 1 ]; then
	echo "ERROR: NEW_OOOQ is not compatible with DEV"
	exit 1
    fi
    if [[ ! -d ~/git ]]; then
	mkdir ~/git
    fi
    if [[ ! -d ~/git/tripleo-quickstart ]]; then
	pushd ~/git/
	if [[ ! -e ~/oooq/git-init.sh ]]; then
	    echo "~/oooq/git-init.sh is missing. aborting"
	    exit 1
	fi
	echo "Cloning master branches of oooq and oooq-extras"
	echo "use 'git review -d <number>' to clone here next time"
	ln -s ~/oooq/git-init.sh
	bash git-init.sh oooq
	popd
    fi
    if [[ -d ~/git/tripleo-quickstart && -d ~/git/tripleo-quickstart-extras ]]; then
	if [[ $OOOQ_REVIEW ]]; then
	    pushd ~/git/tripleo-quickstart
	    git review -d $OOOQ_REVIEW
	    popd
	fi
	if [[ $OOOQ_EXTRAS_REVIEW ]]; then
	    pushd ~/git/tripleo-quickstart-extras
	    git review -d $OOOQ_EXTRAS_REVIEW
	    popd
	fi
	# take advantage of quickstart-extras-requirements.txt being able to use local dir
	echo -n file: > ~/git/tripleo-quickstart/quickstart-extras-requirements.txt
	echo ~/git/tripleo-quickstart-extras >> ~/git/tripleo-quickstart/quickstart-extras-requirements.txt
    fi
    echo "using oooq from ~/git/tripleo-quickstart"
    pushd ~/git/tripleo-quickstart
    bash quickstart.sh --install-deps
fi
# -------------------------------------------------------
if [ $RUNQ -eq 1 ]; then
    time bash quickstart.sh \
    	 --teardown all \
    	 --release $RELEASE \
    	 --nodes ~/oooq/under/nodes.yaml \
    	 --config ~/oooq/under/config.yaml \
	 --clean \
	 --no-clone \
    	 $VIRTHOST

    if [[ $? -gt 0 ]]; then
	popd
	echo "ERROR: initial run of quickstart failed."
	exit 1
    fi
    
    echo "generating network config as per LP1737602"
    bash quickstart.sh \
	 --teardown none \
	 --retain-inventory \
	 --tags 'overcloud-prep-config' \
	 --release $RELEASE \
	 --nodes ~/oooq/under/nodes.yaml \
	 --config ~/oooq/under/config.yaml \
	 $VIRTHOST
fi
# -------------------------------------------------------
if [ $DEV -eq 1 ]; then
    popd # leave ~/git/tripleo-quickstart
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
    if [ $DEV -eq 1 ]; then pushd ~/git/tripleo-quickstart; fi
    bash quickstart.sh \
	 --teardown none \
	 --retain-inventory \
	 --tags 'overcloud-validate' \
	 --release $RELEASE \
	 --nodes nodes.yaml \
	 --config config.yaml \
	 $VIRTHOST
    if [ $DEV -eq 1 ]; then popd; fi
fi
