#!/usr/bin/env bash
# Filename:                pkgs.sh
# Description:             installs packages on undercloud
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2018-01-22 10:03:17 fultonj> 
# -------------------------------------------------------
DOWNLOAD=1
INSTALL_EPEL=1
INSTALL_CENT=1
# -------------------------------------------------------
export SSH_ENV=~/.quickstart/ssh.config.ansible

if [ $DOWNLOAD -eq 1 ]; then
    if [ ! -d pkgs ]; then
	mkdir pkgs
    fi
    for pkg in git-review-1.24-5.el7.noarch.rpm reptyr-0.5-1.el7.x86_64.rpm colordiff-1.0.13-2.el7.noarch.rpm ccze-0.2.1-11.el7.x86_64.rpm emacs-yaml-mode-0.0.12-2.el7.noarch.rpm; do
	l=$(echo $pkg | cut -c-1)
	curl https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/$l/$pkg > pkgs/$pkg
    done
fi

if [ $INSTALL_EPEL -eq 1 ]; then
    # install epel packages without subscribing to epel (being careful)
    if [ ! -d pkgs ]; then
	echo "pkgs directory is missing, try DOWNLOAD=1"
	exit 1
    fi
    scp -r -F $SSH_ENV pkgs stack@undercloud:/home/stack/pkgs
    ssh -F $SSH_ENV stack@undercloud "pushd ~/pkgs ; sudo yum localinstall *.rpm -y ; popd ; rm -rf ~/pkgs"
fi

if [ $INSTALL_CENT -eq 1 ]; then
    ssh -F $SSH_ENV stack@undercloud "sudo yum install tmux screen emacs-nox vim -y" 
fi

# -------------------------------------------------------
# Future feature: also download and cache CentOS packages:
# http://mirror.centos.org/centos/7/os/x86_64/Packages/$pkg
# gpm-libs-1.20.7-5.el7.x86_64.rpm
# liblockfile-1.08-17.el7.x86_64.rpm
# emacs-filesystem-24.3-18.el7.noarch.rpm
# emacs-nox-24.3-18.el7.x86_64.rpm
# emacs-common-24.3-18.el7.x86_64.rpm
# vim-filesystem-7.4.160-1.el7_3.1.x86_64.rpm
# vim-enhanced-7.4.160-1.el7_3.1.x86_64.rpm
# vim-minimal-7.4.160-1.el7_3.1.x86_64.rpm
# vim-common-7.4.160-1.el7_3.1.x86_64.rpm
# screen-4.1.0-0.23.20120314git3c2946.el7_2.x86_64.rpm

# sudo yum install -y ftp://fr2.rpmfind.net/linux/epel/7/x86_64/e/emacs-yaml-mode-0.0.12-2.el7.noarch.rpm
