#!/usr/bin/env bash
# Filename:                double-tunnel.sh
# Description:             Set up SSH tunnel to undercloud 
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-10-08 07:37:06 jfulton> 
# -------------------------------------------------------
# I have a remote hypervisor running VMs for quickstart
# This sets up an SSH tunnel to access the remote undercloud
# For use with emacs tramp:
# (setenv "hypervisor" "/ssh:stack@localhost#2222:/home/stack/")'
# -------------------------------------------------------
hypervisor=192.168.1.50
cmd="grep ProxyCommand .quickstart/ssh.config.ansible | tail -1  | awk {'print \$13'}"
undercloud_port=$(ssh jfulton@$hypervisor $cmd) # e.g. 1.2.3.4:22
echo "Tunneling from localhost:2222 to undercloud:22 via $hypervisor"
ssh -f -L 2222:$undercloud_port -N $hypervisor -l jfulton
echo " ssh stack@localhost -p 2222"
