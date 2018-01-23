Deployed Server Scripts
=======================

These are scripts to help me deploy on pre-provisioned nodes 
as described in the docs ([upstream](https://docs.openstack.org/tripleo-docs/latest/install/advanced_deployment/deployed_server.html) [downstream](https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/12/html-single/director_installation_and_usage/#chap-Configuring_Basic_Overcloud_Requirements_on_Pre_Provisioned_Nodes)).

Scenario
--------

I have three CentOS VMs running on my laptop setup with virt-manager:

- under: hosts undercloud
- ceph: hosts containerized all-in-one ceph install set up by ceph-ansible
- over: hosts containerized all-in-one openstack install

I can reach any host with ansible, e.g. `ansible under -m ping`.

Under
-----

- Undercloud as installed by following the [docs](https://docs.openstack.org/tripleo-docs/latest/install/installation/installation.html).
- under and over have ens9 connected to bridge "exp" with IPs from 192.168.2.0/24
- See [undercloud.conf](undercloud.conf).

Ceph
----

- Run [ceph/init.sh](ceph/init.sh) from laptop and then run ceph-ansible playbook
- See [ceph](ceph/) for more details

Over
----

- Run [init.sh](init.sh) from undercloud to test connection, enable repository and generate tht for the deployment
- Run [deploy.sh](deploy.sh) from undercloud to start deployment
- run [poll.sh](poll.sh) from undercloud to ask overcloud to poll undercloud; otherwise the deployment will fail.
