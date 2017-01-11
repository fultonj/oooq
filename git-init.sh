#!/usr/bin/env bash
# Filename:                git-init.sh
# Description:             configures my git env
# Supported Langauge(s):   GNU Bash 4.2.x
# Time-stamp:              <2016-08-19 17:51:02 stack> 
# -------------------------------------------------------
# Clones the repos that I am interested in.
# -------------------------------------------------------
declare -a repos=(
      'openstack/tripleo-heat-templates' \
      'openstack/puppet-ceph'\
      'openstack-infra/tripleo-ci'\
      # add the next repo here
     );
# -------------------------------------------------------
gerrit_user='fultonj'
git config --global user.email "fulton@redhat.com"
git config --global user.name "John Fulton"
git config --global push.default simple
git config --global gitreview.username $gerrit_user
# -------------------------------------------------------
git review --version
if [ $? -gt 0 ]; then
    echo "installing git-review from upstream"
    dir=/tmp/$(date | md5sum | awk {'print $1'})
    mkdir $dir
    pushd $dir
    curl -O ftp://195.220.108.108/linux/epel/7/x86_64/g/git-review-1.24-5.el7.noarch.rpm
    sudo yum localinstall git-review-1.24-5.el7.noarch.rpm -y 
    popd 
    rm -rf $dir
fi 
# -------------------------------------------------------
pushd ~
for repo in "${repos[@]}"; do
    dir=$(echo $repo | awk 'BEGIN { FS = "/" } ; { print $2 }')
    if [ ! -d ~/$dir ]; then
	git clone https://git.openstack.org/$repo.git
	pushd $dir
	git remote add gerrit ssh://$gerrit_user@review.openstack.org:29418/$repos.git
	git review -s
	popd
    else
	pushd $dir
	git pull --ff-only origin master
	popd
    fi
done
popd
#git remote add remove gerrit

