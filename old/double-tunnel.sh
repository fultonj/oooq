#!/usr/bin/env bash
# Filename:                double-tunnel.sh
# Description:             Set up SSH tunnel to undercloud 
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-12-13 14:19:08 fultonj> 
# -------------------------------------------------------
# I have a remote hypervisor running VMs for quickstart
# This sets up an SSH tunnel to access the remote undercloud
# For use with emacs tramp:
# (setenv "hypervisor" "/ssh:stack@localhost#2222:/home/stack/")'
# -------------------------------------------------------
#echo "Removing old localhost entries in ~/.ssh/known_hosts"
grep -n localhost ~/.ssh/known_hosts | grep 2222 | awk {'print $1'} | awk 'BEGIN { FS = ":" } ; { print $1 }' > /tmp/tunnel-lines
for i in $(cat /tmp/tunnel-lines); do
    opt='d'
    cmd=$i$opt
    sed -i $cmd ~/.ssh/known_hosts
done
# -------------------------------------------------------
hypervisor=192.168.1.50
cmd="grep ProxyCommand .quickstart/ssh.config.ansible | tail -1  | awk {'print \$13'}"
undercloud_port=$(ssh jfulton@$hypervisor $cmd) # e.g. 1.2.3.4:22
echo "Tunneling from localhost:2222 to undercloud:22 via $hypervisor"
ssh -f -L 2222:$undercloud_port -N $hypervisor -l jfulton
echo " ssh stack@localhost -p 2222"
