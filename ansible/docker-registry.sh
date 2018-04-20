#!/usr/bin/env bash
source ~/stackrc

LOCAL=1

if [[ $LOCAL -eq 0 ]]; then
    openstack overcloud container image prepare --output-env-file ~/docker_registry.yaml
    exit 0
fi

tag="current-tripleo-rdo"
if [[ -f overcloud_containers.yaml ]] ; then
    echo "uploading container registry based on overcloud_containers.yaml"
    sudo openstack overcloud container image upload --config-file overcloud_containers.yaml --verbose
    echo $?
    echo "Note the error code above ^ (is it not 0?)"
    
    echo "The following images are now in the local registry"
    curl -s http://192.168.24.1:8787/v2/_catalog | jq "."

    attempted=$(cat overcloud_containers.yaml | grep -v container_images | wc -l)
    uploaded=$(curl -s http://192.168.24.1:8787/v2/_catalog | jq "." | egrep "master|ceph" | wc -l)
    echo "Of the $attempted docker images, only $uploaded were uploaded"
    echo "Look for a pattern of the ones that did not make it in the following: "
    
    for l in $(cat overcloud_containers.yaml | awk {'print $3'} | awk 'BEGIN { FS="/" } { print $3 }' | sed s/:current-tripleo-rdo//g ); do
	echo $l
	curl -s http://192.168.24.1:8787/v2/_catalog | jq "." | grep -n $l ;
    done	

    echo "Considering re-running 'openstack overcloud container image upload' if missing iamges are necessary"
    echo ""
    
    echo "Creating ~/docker_registry.yaml with references to local registry"
    openstack overcloud container image prepare \
              --namespace=192.168.24.1:8787/master \
              --tag=$tag \
              --set ceph_namespace=192.168.24.1:8787 \
              --set ceph_image=ceph/daemon \
              --set ceph_tag=v3.0.1-stable-3.0-luminous-centos-7-x86_64 \
              --env-file=/home/stack/docker_registry.yaml

    echo "Workaround missing current-tripleo-rdo for centos-binary-keepalived"
    grep keepalived /home/stack/docker_registry.yaml
    sed -i s/centos-binary-keepalived:current-tripleo-rdo/centos-binary-keepalived:tripleo-ci-testing/g /home/stack/docker_registry.yaml

    echo "~/docker_registry.yaml has had the following centos-binary-keepalived update"
    grep keepalived /home/stack/docker_registry.yaml
else
    echo "overcloud_containers.yaml is not in current directory"
fi
