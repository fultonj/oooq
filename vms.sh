#!/usr/bin/env bash
# Filename:                vms.sh
# Description:             runs commands as stack@virthost
# Time-stamp:              <2017-02-03 20:23:36 jfulton> 
# -------------------------------------------------------
# another crude but effective wrapper for the lazy
# -------------------------------------------------------
case "$1" in
        undercloud)
	    case "$2" in
		stop)
		    cmd='virsh shutdown undercloud'
		    ;;
		start)
		    cmd='virsh start undercloud'
		    ;;
		suspend)
		    cmd='virsh suspend undercloud'
		    ;;
		resume)
		    cmd='virsh resume undercloud'
		    ;;
		*)
		    cmd="virsh list --all"
	    esac
            ;;
        resume)
	    cmd='for vm in $(virsh list --all | awk {"print \$2"} | egrep -v "Name|^$"); do echo "running resume $vm"; virsh resume $vm; done'
            ;;
        stop)
            cmd='for vm in $(virsh list --all | awk {"print \$2"} | egrep -v "Name|^$"); do echo "running shutdown $vm"; virsh shutdown $vm; done'
	    echo $cmd
            ;;
        suspend)
	    cmd='for vm in $(virsh list --all | awk {"print \$2"} | egrep -v "Name|^$"); do echo "running suspend $vm"; virsh suspend $vm; done'
            ;;
        start)
            cmd='for vm in $(virsh list --all | awk {"print \$2"} | egrep -v "Name|^$"); do echo "running start $vm"; virsh start $vm; done'
            ;;
	*)
	    cmd="virsh list --all"
esac
# -------------------------------------------------------
export SSH_ENV=~/.quickstart/ssh.config.ansible
ssh -q -F $SSH_ENV virthost "$cmd"
