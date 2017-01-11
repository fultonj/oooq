#!/usr/bin/env bash
# Filename:                add-disks.sh
# Description:             Adds /dev/vd{b,c,d,e} to ceph_0
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-01-10 23:50:54 jfulton> 
# -------------------------------------------------------
test "$(whoami)" != 'stack' \
    && (echo "This must be run by the stack user on the hypervisor"; exit 1)

pushd /home/stack/.quickstart/pool/
rm -f ceph_0-osd-*
for i in b c d e; do 
  qemu-img create -f qcow2 -o preallocation=metadata ceph_0-osd-$i.qcow2 10G;
  virsh attach-disk ceph_0 --source /home/stack/.quickstart/pool/ceph_0-osd-$i.qcow2 --target vd$i --persistent
done
qemu-img create -f qcow2 -o preallocation=metadata ceph_0-osd-journal.qcow2 20G; 
virsh attach-disk ceph_0 --source /home/stack/.quickstart/pool/ceph_0-osd-journal.qcow2 --target vdf --persistent
popd
