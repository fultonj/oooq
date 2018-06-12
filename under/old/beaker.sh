#!/bin/bash

if [ -f /usr/bin/yum ]; then
    OS_TYPE='centos7'
elif [ -f /usr/bin/apt-get ]; then
    OS_TYPE='trusty'
fi

sudo yum-config-manager --enable rhel-7-server-optional-rpms
#yum -y install redhat-lsb-core
sudo yum -y install ruby-devel rubygems gcc gcc-c++ zlib-devel 

sudo gem install bundler --no-rdoc --no-ri --verbose
mkdir .bundled_gems
export GEM_HOME=`pwd`/.bundled_gems
bundle install
export BEAKER_set=nodepool-$OS_TYPE
export BEAKER_debug=yes

#bundle exec rspec spec/acceptance
#bundle exec rake spec


# workaround the following:
#  https://github.com/openstack/puppet-openstack-integration/commit/2b57a24d35a833ce543e139c2d04bcb229d1a0be
#  https://github.com/openstack/puppet-openstack-integration/commit/c87bea7761f3ef50fb05bf934ec5842edd989a88

bundle exec rake spec_clean
bundle exec rake spec_prep
pushd spec/fixtures/modules/concat
git checkout 5c4a9141d08a7b23dcada029d23b82590632d0f4
popd
pushd spec/fixtures/modules/apt
git checkout 3f6863ac4c97f834bebc811852452b073d202682
popd
bundle exec rake spec_standalone
