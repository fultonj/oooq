#!/usr/bin/env bash
if [ $# -eq 0 ]; then
    echo "USAGE: $0 <regex matching server in 'nova list' to have /dev/vd{b,c,d} zapped>"
    exit 1
fi
source ~/stackrc
server=$1
ip=$(nova list | grep $server | awk {'print $12'} | sed s/ctlplane=//g)
ssh heat-admin@$ip "for d in `echo /dev/vd{b,c,d}`; do sudo sgdisk -Z \$d; sudo sgdisk -g \$d; done; sudo partprobe"
