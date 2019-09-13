#!/usr/bin/env bash
source ~/stackrc

VERSION=ROCKY
# VERSION=QUEENS

if [[ $VERSION == "ROCKY" ]]; then
    # for now manually apply https://review.openstack.org/#/c/604241
    
    echo "resource_registry:" > ~/no-odl.yaml
    echo "  OS::TripleO::Services::OpenDaylightApi: OS::Heat::None" >> ~/no-odl.yaml
    echo "  OS::TripleO::Services::OpenDaylightOvs: OS::Heat::None" >> ~/no-odl.yaml
    echo "resource_registry:" > ~/no-ovn.yaml
    echo "  OS::TripleO::Services::OVNDBs: OS::Heat::None" >> ~/no-ovn.yaml
    echo "  OS::TripleO::Services::OVNController: OS::Heat::None" >> ~/no-ovn.yaml
    echo "  OS::TripleO::Services::OVNMetadataAgent: OS::Heat::None" >> ~/no-ovn.yaml

    sudo openstack tripleo container image prepare default \
	      --local-push-destination \
	      --output-env-file ~/containers-prepare-parameter.yaml

    # for now manually apply https://review.openstack.org/#/c/603323/
    sed -i 's/ceph_tag:.*/ceph_tag:\ v3.1.0-stable-3.1-luminous-centos-7-x86_64/g' ~/containers-prepare-parameter.yaml

    sudo openstack tripleo container image prepare \
      -e ~/containers-prepare-parameter.yaml \
      -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
      -e ~/no-odl.yaml \
      -e ~/no-ovn.yaml \
      --output-env-file ~/containers-default-parameters.yaml

fi

if [[ $VERSION == "QUEENS" ]]; then

    openstack overcloud container image prepare \
	      --namespace docker.io/tripleomaster \
	      --tag current-tripleo \
	      --tag-from-label rdo_version \
	      --push-destination 192.168.24.1:8787 \
	      --output-env-file ~/docker_registry.yaml \
	      --output-images-file overcloud_containers.yaml

    sudo time openstack overcloud container image upload --config-file overcloud_containers.yaml
fi

curl -s http://192.168.24.1:8787/v2/_catalog | jq "."
