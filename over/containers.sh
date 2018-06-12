#!/usr/bin/env bash

openstack overcloud container image prepare \
	  --namespace docker.io/tripleomaster \
	  --tag current-tripleo \
	  --tag-from-label rdo_version \
	  --push-destination 192.168.24.1:8787 \
	  --output-env-file ~/docker_registry.yaml \
	  --output-images-file overcloud_containers.yaml

sudo time openstack overcloud container image upload --config-file overcloud_containers.yaml

curl -s http://192.168.24.1:8787/v2/_catalog | jq "."
