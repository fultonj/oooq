#!/usr/bin/env bash
source ~/stackrc

VERSION=ROCKY
# VERSION=QUEENS

if [[ $VERSION == "ROCKY" ]]; then
    sudo openstack tripleo container image prepare default \
	      --local-push-destination \
	      --output-env-file containers-prepare-parameter.yaml

    sudo openstack tripleo container image prepare \
      -e ~/containers-prepare-parameter.yaml \
      -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
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
