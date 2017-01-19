#!/usr/bin/env bash
# Filename:                setup-deploy-artifacts.sh
# Description:             sets up dev env
# Supported Langauge(s):   GNU Bash 4.2.x
# Time-stamp:              <2017-01-19 00:04:44 jfulton>
# -------------------------------------------------------
# This is a quick shell script to set up what's desc in: 
# http://hardysteven.blogspot.com/2016/08/tripleo-deploy-artifacts-and-puppet.html
# -------------------------------------------------------
# Run this on the undercloud to get the following dirs:  
# 
# ~/tripleo-common
#   
# ~/tripleo-heat-templates
# ~/templates -> tripleo-heat-templates # symlink to above
# 
# ~/puppet-modules/
# ~/puppet-modules/puppet-ceph
# ~/puppet-modules/puppet-openstack-integration
# ~/puppet-modules/puppet-*
# 
# Then do all deployments using
# 
#  openstack overcloud deploy --templates ~/templates/ -e ...
# 
# The Heat templates will be the upstream ones directly from git.
# You may then checkout different reviews or edit your own review 
# of the THT to for the deploy. 
# 
# The Puppet modules will be the upstream ones directly from git
# and they will be uploaded to the overcloud with each deploy 
# because they are in ~/puppet-modules/ and the scripts from
# ~/tripleo-common will have set them up as deploy artifacts
# as described in the shardy blog post above. Thus, you do not
# have to worry about the puppet modules in the overcloud images.
# 
# You will then be able to 'git review -d x' and 'git review -d y'
# in puppet or tht to test deployment of different changes.
# 
# The script also sets up git review with a specific gerrit
# username 
# -------------------------------------------------------
declare -a repos=(
      'openstack/tripleo-common'\
      'openstack/tripleo-heat-templates'\
      'openstack/puppet-ceph'\
      'openstack/puppet-tripleo'\
      #'openstack/puppet-openstack-integration'\
      #'openstack-infra/tripleo-ci'\
      # add the next repo here
);
# The first item must be tripleo-common.
# All repos will be put in ~ except any containing
# the string "puppet", which will be in ~/puppet-modules
# -------------------------------------------------------
gerrit_user='fultonj'
git config --global user.email "fulton@redhat.com"
git config --global user.name "John Fulton"
git config --global push.default simple
git config --global gitreview.username $gerrit_user
# -------------------------------------------------------
git review --version
if [ $? -gt 0 ]; then
    # assume we are not using epel but want git review
    echo "installing git-review from upstream"
    dir=/tmp/$(date | md5sum | awk {'print $1'})
    mkdir $dir
    pushd $dir
    pkg=git-review-1.24-5.el7.noarch.rpm
    curl -O https://dl.fedoraproject.org/pub/epel/7/x86_64/g/$pkg
    sudo yum localinstall $pkg -y 
    popd 
    rm -rf $dir
fi 
# -------------------------------------------------------
if [ ! -d ~/puppet-modules ]; then
    mkdir ~/puppet-modules
fi
# -------------------------------------------------------
pushd ~
for repo in "${repos[@]}"; do
    repo=$(echo $repo | xargs) # trim whitespace 
    echo "Cloning $repo"
    dir=$(echo $repo | awk 'BEGIN { FS = "/" } ; { print $2 }')
    if [[ $repo == *"puppet"* ]]; then
	pushd ~/puppet-modules
	# change name for when it lands in /etc/puppet/modules on overcloud
	dir=$(echo $dir | sed s/puppet-//g)
    fi
    if [ ! -d $dir ]; then
	url=https://git.openstack.org/$repo.git
	remove_file_count=$(git ls-remote $url | wc -l)
	if [ $remove_file_count -gt 0 ]; then
	    # rename it to drop the "puppet-" xor it works for non-puppet too
	    git clone $url $dir
	    if [ -d $dir ]; then
		pushd $dir
		git remote add gerrit ssh://$gerrit_user@review.openstack.org:29418/$repo.git
		git review -s
		popd
	    else
		echo "directory $dir not found"
	    fi
	else
	    echo "no results from:  \"git ls-remote $url\""
	fi
    else
	pushd $dir
	git pull --ff-only origin master
	popd
    fi
    if [[ $repo == *"puppet"* ]]; then
	popd # out of ~/puppet-modules
    fi
done
popd
# -------------------------------------------------------
if [ ! -L ~/templates ]; then
    ln -s ~/tripleo-heat-templates ~/templates
fi
# -------------------------------------------------------
common=$(grep tripleo-common ~/.bashrc | wc -l)
if [ $common -eq 0 ]; then
    echo 'export PATH="$PATH:/home/stack/tripleo-common/scripts"' >> ~/.bashrc
    source ~/.bashrc
fi
