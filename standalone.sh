#!/usr/bin/env bash
# -------------------------------------------------------
# using this network option and do the steps in this doc for me
# https://docs.openstack.org/tripleo-docs/latest/install/containers_deployment/standalone.html#networking-details
# -------------------------------------------------------
REPO=0
INSTALL=0
CONTAINERS=0
PARAMS=0
DEPLOY=1

# I am using a VM on my fedora laptop and it needs to be able to ping its gateway
# so I run this to workaround the default security setup.
#sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -p icmp -s 192.168.122.0/24 -d 192.168.122.1 -j ACCEPT
#sudo systemctl restart firewalld.service

export IP=192.168.24.2
export NETMASK=24
export INTERFACE=eth0

if [[ $REPO -eq 1 ]]; then
    if [[ ! -d ~/rpms ]]; then mkdir ~/rpms; fi
    url=https://trunk.rdoproject.org/centos7/current/
    rpm_name=$(curl $url | grep python2-tripleo-repos | sed -e 's/<[^>]*>//g' | awk 'BEGIN { FS = ".rpm" } ; { print $1 }')
    rpm=$rpm_name.rpm
    curl -f $url/$rpm -o ~/rpms/$rpm
    if [[ -f ~/rpms/$rpm ]]; then
	sudo yum install -y ~/rpms/$rpm
	sudo -E tripleo-repos current-tripleo-dev
	sudo yum repolist
	sudo yum update -y
    else
	echo "$rpm is missing. Aborting."
	exit 1
    fi
fi

if [[ $INSTALL -eq 1 ]]; then
    sudo yum install -y python-tripleoclient
fi

if [[ $CONTAINERS -eq 1 ]]; then
    openstack tripleo container image prepare default \
      --output-env-file $HOME/containers-prepare-parameters.yaml
fi



if [[ $PARAMS -eq 1 ]]; then
    
    cat <<EOF > $HOME/standalone_parameters.yaml
parameter_defaults:
  CloudName: $IP
  ControlPlaneStaticRoutes: []
  Debug: true
  DeploymentUser: $USER
  DnsServers:
    - 8.8.4.4
    - 8.8.8.8
  DockerInsecureRegistryAddress:
    - $IP:8787
  NeutronPublicInterface: $INTERFACE
  # domain name used by the host
  NeutronDnsDomain: localdomain
  # re-use ctlplane bridge for public net, defined in the standalone
  # net config (do not change unless you know what you're doing)
  NeutronBridgeMappings: datacentre:br-ctlplane
  NeutronPhysicalBridge: br-ctlplane
  # enable to force metadata for public net
  #NeutronEnableForceMetadata: true
  StandaloneEnableRoutedNetworks: false
  StandaloneHomeDir: $HOME
  StandaloneLocalMtu: 1500
  # Needed if running in a VM, not needed if on baremetal
  StandaloneExtraConfig:
    nova::compute::libvirt::services::libvirt_virt_type: qemu
    nova::compute::libvirt::libvirt_virt_type: qemu
EOF
fi

if [[ $DEPLOY -eq 1 ]]; then
    openstack tripleo deploy \
      --templates \
      --local-ip=$IP/$NETMASK \
      -e /usr/share/openstack-tripleo-heat-templates/environments/standalone.yaml \
      -r /usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml \
      -e $HOME/containers-prepare-parameters.yaml \
      -e $HOME/standalone_parameters.yaml \
      --output-dir $HOME \
      --standalone
fi
