#!/usr/bin/env bash
# -------------------------------------------------------
# payload under heredoc
# -------------------------------------------------------
cat > /tmp/mkinv.yaml <<- "EOF"
---
- hosts: Controller
  name: gather ceph mon nodes
  tasks:
    - name: remove previous inventory file if present
      file:
        path: /tmp/ceph-inventory.yml
        state: absent
      delegate_to: localhost
      run_once: true
    - name: create inventory file
      file:
        path: /tmp/ceph-inventory.yml
        state: touch
      delegate_to: localhost
      run_once: true
    - command: hostname -s
      register: mon_hostnames
    - name: Create MON hostgroup in inventory file
      lineinfile:
        line: "[mons]"
        dest: "/tmp/ceph-inventory.yml"
        insertafter: EOF
      delegate_to: localhost
    - name: Append MON hostnames to inventory file
      lineinfile:
        line: "{{ item }} ansible_ssh_user=heat-admin"
        dest: "/tmp/ceph-inventory.yml"
        insertafter: EOF
      delegate_to: localhost
      with_items: "{{ mon_hostnames.stdout }}"

- hosts: CephStorage
  name: gather ceph osd nodes
  tasks: 
    - command: hostname -s
      register: osd_hostnames
    - name: Create OSD hostgroup in inventory file
      lineinfile:
        line: "[osds]"
        dest: "/tmp/ceph-inventory.yml"
        insertafter: EOF
      delegate_to: localhost
    - name: Append OSD hostnames to inventory file
      lineinfile:
        line: "{{ item }} ansible_ssh_user=heat-admin"
        dest: "/tmp/ceph-inventory.yml"
        insertafter: EOF
      delegate_to: localhost
      with_items: "{{ osd_hostnames.stdout }}"

- hosts:
    - Controller
    - CephStorage
  name: Configure /etc/hosts on undercloud
  tasks:
    - shell: grep $(hostname).ctlplane /etc/hosts|awk '{print $1, $3}'|sed 's/\.ctlplane//g'
      register: ceph_etc_hostnames
    - name: Append ceph hostnames and IPs to /etc/hosts
      lineinfile:
        line: "{{ item }}"
        dest: "/etc/hosts"
        insertafter: EOF
      delegate_to: localhost
      become: true
      with_items: "{{ ceph_etc_hostnames.stdout }}"
EOF
# -------------------------------------------------------
if [[ ! -e /tmp/mkinv.yaml ]]; then
   echo "unable to create /tmp/mkinv.yaml. exiting"
   exit 1
fi
if [ -d ~/ansible ]; then
    echo "~/ansible already exists. exiting"
    exit 1
fi

mkdir -v ~/ansible
pushd ~/ansible
tripleo-ansible-inventory --static-yaml-inventory tripleo-inventory.yml
ansible-playbook -b --ssh-extra-args "-o StrictHostKeyChecking=no" -i tripleo-inventory.yml /tmp/mkinv.yaml
if [[ ! -e /tmp/ceph-inventory.yml ]]; then
    echo "unable to create /tmp/ceph-inventory.yml. exiting"
    exit 1
fi
cp /tmp/ceph-inventory.yml ceph-inventory.yml
ansible --ssh-extra-args "-o StrictHostKeyChecking=no" -i ceph-inventory.yml -m ping all
popd

echo "The following ansible inventories are now available:"
ls ~/ansible/*.yml
