#!/bin/bash

if [ -f /usr/bin/yum ]; then
    OS_TYPE='centos7'
elif [ -f /usr/bin/apt-get ]; then
    OS_TYPE='trusty'
fi

#yum -y install redhat-lsb-core
sudo yum -y install ruby-devel rubygems gcc gcc-c++ zlib-devel 

sudo gem install bundler --no-rdoc --no-ri --verbose
mkdir .bundled_gems
export GEM_HOME=`pwd`/.bundled_gems
bundle install
export BEAKER_set=nodepool-$OS_TYPE
export BEAKER_debug=yes
bundle exec rspec spec/acceptance
