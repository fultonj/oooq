#!/usr/bin/env bash
# Filename:                triple-tunnel.sh
# Description:             Set up SSH tunnel to undercloud 
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-12-13 14:17:43 fultonj> 
# -------------------------------------------------------
# I have a remote hypervisor running VMs for quickstart
# I can only access that hypervisor via a bridge server
# Set up an SSH tunnel via the bridge to the hypervisor
# Set up second SSH tunnel via the first to the undercloud
# For use with emacs tramp:
# (setenv "tunnel3" "/ssh:stack@localhost#3333:/home/stack/")
# -------------------------------------------------------
#echo "Removing old localhost entries in ~/.ssh/known_hosts"
grep -n localhost ~/.ssh/known_hosts | grep 333 | awk {'print $1'} | awk 'BEGIN { FS = ":" } ; { print $1 }' > /tmp/tunnel-lines
for i in $(cat /tmp/tunnel-lines); do
    opt='d'
    cmd=$i$opt
    sed -i $cmd ~/.ssh/known_hosts
done
# -------------------------------------------------------
bridge=10.19.139.49
hypervisor=192.168.1.253
ssh -f -L 3332:$hypervisor:22 -N stack@$bridge
echo "Access hypervisor with: ooo@localhost -p 3332"
ssh -A ooo@localhost -p 3332 "uname -a"
# determine undercloud IP
cmd="grep ProxyCommand .quickstart/ssh.config.ansible | tail -1  | awk {'print \$13'}"
undercloud_port=$(ssh ooo@localhost -p 3332 $cmd) # e.g. 1.2.3.4:22
ssh -A -f -L 3333:$undercloud_port -N ooo@localhost -p 3332
echo "Access undercloud with: ssh stack@localhost -p 3333"
ssh stack@localhost -p 3333 "uname -a"

# -------------------------------------------------------
echo "Install ssh key"
ssh-copy-id stack@localhost -p 3333
