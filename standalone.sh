#!/usr/bin/env bash
# -------------------------------------------------------
# using this network option and do the steps in this doc for me
# https://docs.openstack.org/tripleo-docs/latest/install/containers_deployment/standalone.html#networking-details
# -------------------------------------------------------
REPO=1
INSTALL=1
CONTAINERS=1
PARAMS=1
CEPH_PREP=1
DEPLOY=1
TEST=0
CEPH=0
GLANCE=0
NOVA=0
DEPS=0
# -------------------------------------------------------
PROVIDER_NETWORK=1
# ^ should testing be done using a provider network or a tenant network?

# I am using a VM on my fedora laptop and it needs to be able to ping its gateway
# so I run this to workaround the default security setup.
#sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -p icmp -s 192.168.122.0/24 -d 192.168.122.1 -j ACCEPT
#sudo systemctl restart firewalld.service
# -------------------------------------------------------
export IP=192.168.24.2
export NETMASK=24
export INTERFACE=eth0
export FETCH=/tmp/ceph_ansible_fetch

if [[ $REPO -eq 1 ]]; then
    if [[ ! -d ~/rpms ]]; then mkdir ~/rpms; fi
    url=https://trunk.rdoproject.org/centos7/current/
    rpm_name=$(curl -k $url | grep python2-tripleo-repos | sed -e 's/<[^>]*>//g' | awk 'BEGIN { FS = ".rpm" } ; { print $1 }')
    rpm=$rpm_name.rpm
    curl -k -f $url/$rpm -o ~/rpms/$rpm
    if [[ -f ~/rpms/$rpm ]]; then
	sudo yum install -y ~/rpms/$rpm
	sudo -E tripleo-repos current-tripleo-dev ceph
	sudo yum repolist
	sudo yum update -y
    else
	echo "$rpm is missing. Aborting."
	exit 1
    fi
fi

if [[ $INSTALL -eq 1 ]]; then
    sudo yum install -y python-tripleoclient ceph-ansible gdisk
fi

if [[ $CONTAINERS -eq 1 ]]; then
    openstack tripleo container image prepare default \
      --output-env-file $HOME/containers-prepare-parameters.yaml
    # hack add last known working ceph tag version in my environment
    sed -i 's/ceph_tag:.*/ceph_tag:\ v3.1.0-stable-3.1-luminous-centos-7-x86_64/g' $HOME/containers-prepare-parameters.yaml
fi

if [[ $CEPH_PREP -eq 1 ]]; then
    # create a block device
    if [[ ! -e /dev/loop3 ]]; then # ensure /dev/loop3 does not exist before making it
        command -v losetup >/dev/null 2>&1 || { sudo yum -y install util-linux; }
        sudo dd if=/dev/zero of=/var/lib/ceph-osd.img bs=1 count=0 seek=7G
        sudo losetup /dev/loop3 /var/lib/ceph-osd.img
    elif [[ -f /var/lib/ceph-osd.img ]]; then #loop3 and ceph-osd.img exist
        echo "warning: looks like ceph loop device already created. Trying to continue"
    else
        echo "error: /dev/loop3 exists but not /var/lib/ceph-osd.img. Exiting."
        exit 1
    fi
    sgdisk -Z /dev/loop3
    sudo lsblk
    if [[ ! -d $FETCH ]]; then
	mkdir $FETCH
    fi
    chmod 777 $FETCH
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
  CephAnsibleDisksConfig:
    devices:
      - /dev/loop3
    journal_size: 1024
  CephAnsibleExtraConfig:
    osd_scenario: collocated
    osd_objectstore: filestore
    cluster_network: 192.168.24.0/24
    public_network: 192.168.24.0/24
  CephAnsiblePlaybookVerbosity: 3
  CephPoolDefaultSize: 1
  CephPoolDefaultPgNum: 32
  LocalCephAnsibleFetchDirectoryBackup: $FETCH
EOF
fi

if [[ $DEPLOY -eq 1 ]]; then
    if [[ ! -d ~/templates ]]; then
	ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
    fi
    openstack tripleo deploy \
      --templates ~/templates \
      --local-ip=$IP/$NETMASK \
      -e ~/templates/environments/standalone.yaml \
      -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
      -r ~/templates/roles/Standalone.yaml \
      -e $HOME/containers-prepare-parameters.yaml \
      -e $HOME/standalone_parameters.yaml \
      --output-dir $HOME \
      --standalone \
      --keep-running
fi

# -------------------------------------------------------
# TESTING ONLY
# -------------------------------------------------------

if [[ $TEST -eq 1 ]]; then
    export OS_CLOUD=standalone
    openstack endpoint list > /dev/null
    if [[ $? -gt 0 ]]; then
	echo "Cannot list end points. Aborting"
	exit 1
    fi
    export OS_CLOUD=standalone
    export GATEWAY=192.168.24.1
    export STANDALONE_HOST=192.168.24.2
    if [[ $PROVIDER_NETWORK -eq 1 ]]; then
	export VROUTER_IP=192.168.24.3
    else
	export PRIVATE_NETWORK_CIDR=192.168.100.0/24
    fi
    export PUBLIC_NETWORK_CIDR=192.168.24.0/24
    export PUBLIC_NET_START=192.168.24.4
    export PUBLIC_NET_END=192.168.24.5
    export DNS_SERVER=8.8.8.8
    export MON=$(docker ps --filter 'name=ceph-mon' --format "{{.ID}}")

    if [[ $CEPH -eq 1 ]]; then
	docker exec -ti $MON ceph -s
	docker exec -ti $MON ceph df
	echo ""
	docker exec -ti $MON ceph osd dump | grep pool
	echo ""
    fi

    if [[ $GLANCE -eq 1 ]]; then
	# delete all images if any
	for ID in $(openstack image list -f value -c ID); do
	    openstack image delete $ID;
	done
	# download cirros image only if necessary
	IMG=cirros-0.4.0-x86_64-disk.img
	RAW=$(echo $IMG | sed s/img/raw/g)
	if [ ! -f $RAW ]; then
	    if [ ! -f $IMG ]; then
		echo "Could not find qemu image $img; downloading a copy."
		curl -# https://download.cirros-cloud.net/0.4.0/$IMG > $IMG
	    fi
	    echo "Could not find raw image $RAW; converting."
	    qemu-img convert -f qcow2 -O raw $IMG $RAW
	fi
	docker exec -ti $MON rbd -p images ls -l
	openstack image create cirros --container-format bare --disk-format raw --public --file $RAW
	docker exec -ti $MON rbd -p images ls -l
    fi

    if [[ $NOVA -eq 1 ]]; then
	if [[ $DEPS -eq 1 ]]; then
	    echo "Checking the following dependencies..."
	    if [[ $(getenforce) == "Enforcing" ]]; then
		# workaround /usr/libexec/qemu-kvm: Permission denied
		setenforce 0
		getenforce
	    fi
	    echo "- selinux permissive"
	    IMAGE_ID=$(openstack image show cirros -f value -c id)
	    if [[ -z $IMAGE_ID ]]; then
		echo "Unable to find cirros image; re-run with GLANCE=1"
		exit 1
	    fi
	    echo "- glance image"
	    # create basic security group to allow ssh/ping/dns only if necessary
	    SEC_GROUP_ID=$(openstack security group show basic -f value -c id)
	    if [[ -z $SEC_GROUP_ID ]]; then
		openstack security group create basic
		# allow ssh
		openstack security group rule create basic --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0
		# allow ping
		openstack security group rule create --protocol icmp basic
		# allow DNS
		openstack security group rule create --protocol udp --dst-port 53:53 basic
	    fi
	    echo "- security groups"
	    # create public/private network only if necessary 
	    PUB_NET_ID=$(openstack network show public -c id -f value)
	    if [[ -z $PUB_NET_ID ]]; then
		openstack network create --external --provider-physical-network datacentre --provider-network-type flat public
	    fi
	    PUB_SUBNET_ID=$(openstack network show public -c subnets -f value)
	    if [[ -z $PUB_SUBNET_ID ]]; then
		if [[ $PROVIDER_NETWORK -eq 1 ]]; then
		    openstack subnet create public-net \
			--subnet-range $PUBLIC_NETWORK_CIDR \
			--gateway $GATEWAY \
			--allocation-pool start=$PUBLIC_NET_START,end=$PUBLIC_NET_END \
			--network public \
			--host-route destination=169.254.169.254/32,gateway=$VROUTER_IP \
			--host-route destination=0.0.0.0/0,gateway=$GATEWAY \
			--dns-nameserver $DNS_SERVER
		else
		    openstack subnet create public-net \
			  --subnet-range $PUBLIC_NETWORK_CIDR \
			  --no-dhcp \
			  --gateway $GATEWAY \
			  --allocation-pool start=$PUBLIC_NET_START,end=$PUBLIC_NET_END \
			  --network public
		fi
	    fi
	    echo "- public networks"
	    if [[ $PROVIDER_NETWORK -eq 0 ]]; then
		PRI_NET_ID=$(openstack network show private -c id -f value)
		if [[ -z $PRI_NET_ID ]]; then
		    openstack network create --internal private
		fi
		PRI_SUBNET_ID=$(openstack network show private -c subnets -f value)
		if [[ -z $PRI_SUBNET_ID ]]; then
		    openstack subnet create private-net \
			--subnet-range $PRIVATE_NETWORK_CIDR \
			--network private
		fi
		echo "- private networks"
	    fi
	    # create router only if necessary
	    ROUTER_ID=$(openstack router show vrouter -f value -c id)
	    if [[ -z $ROUTER_ID ]]; then
		if [[ $PROVIDER_NETWORK -eq 1 ]]; then
		    # vrouter needed for metadata route
		    # NOTE(aschultz): In this case we're creating a fixed IP because we need
		    # to create a manual route in the subnet for the metadata service
		    openstack router create vrouter
		    openstack port create --network public --fixed-ip \
			subnet=public-net,ip-address=$VROUTER_IP vrouter-port
		    openstack router add port vrouter vrouter-port
		else
		    # IP will be automatically assigned from allocation pool of the subnet
		    openstack router create vrouter
		    openstack router set vrouter --external-gateway public
		    openstack router add subnet vrouter private-net
		fi
	    fi
	    echo "- router"
	    if [[ $PROVIDER_NETWORK -eq 0 ]]; then
	        # create floating IP only if necessary
	        FLOATING_IP=$(openstack floating ip list -f value -c "Floating IP Address")
		if [[ -z $FLOATING_IP ]]; then
		    openstack floating ip create public
		    FLOATING_IP=$(openstack floating ip list -f value -c "Floating IP Address")
		fi
		if [[ -z $FLOATING_IP ]]; then
		    echo "Unable to use existing or create new floating IP"
		    exit 1
		fi
		echo "- floating IP"
	    fi
	    # create flavor only if necessary
	    FLAVOR_ID=$(openstack flavor show tiny -f value -c id)
	    if [[ -z $FLAVOR_ID ]]; then
		openstack flavor create --ram 512 --disk 1 --vcpu 1 --public tiny
	    fi
	    echo "- flavor"
	    KEYPAIR_ID=$(openstack keypair show demokp -f value -c user_id)
	    if [[ ! -z $KEYPAIR_ID ]]; then
		openstack keypair delete demokp
		if [[ -f ~/demokp.pem ]]; then
		    rm -f ~/demokp.pem
		fi
	    fi
	    openstack keypair create demokp > ~/demokp.pem
	    chmod 600 ~/demokp.pem
	    echo "- SSH keypairs"
	    echo ""
	fi	
	echo "Deleting previous Nova server(s)"
	for ID in $(openstack server list -f value -c ID); do
	    openstack server delete $ID;
	done

	echo "Launching Nova server"
	if [[ $PROVIDER_NETWORK -eq 1 ]]; then
	    openstack server create --flavor tiny --image cirros --key-name demokp --network public --security-group basic myserver
	else
	    openstack server create --flavor tiny --image cirros --key-name demokp --network private --security-group basic myserver
	fi
	STATUS=$(openstack server show myserver -f value -c status)
	echo "Server status: $STATUS (waiting)"
	while [[ $STATUS == "BUILD" ]]; do
	    sleep 1
	    echo -n "."
	    STATUS=$(openstack server show myserver -f value -c status)
	done
	echo ""
	if [[ $STATUS == "ERROR" ]]; then
	    echo "Server build failed; aborting."
	    exit 1
	fi
	if [[ $STATUS == "ACTIVE" ]]; then
	    openstack server list
	    echo -e "\nListing objects in Ceph vms pool:\n"
	    docker exec -ti $MON rbd -p vms ls -l
	    echo ""
	    if [[ $PROVIDER_NETWORK -eq 1 ]]; then
		SRV_IP=$(openstack server show myserver -c addresses -f value | sed s/public=//g)
	    else
		SRV_IP=$(openstack floating ip list -f value -c "Floating IP Address")
	    fi
	    echo "Will attempt to SSH into $SRV_IP for 30 seconds"
	    i=0
	    while true; do
		ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
		    -i ~/demokp.pem cirros@$SRV_IP "exit" 2> /dev/null && break
		echo -n "."
		sleep 1
		i=$(($i+1))
		if [[ $i -gt 30 ]]; then break; fi
	    done
	    echo ""
	    ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
		-i ~/demokp.pem cirros@$SRV_IP "uname -a; lsblk" 
	    echo -e "\nssh -o \"UserKnownHostsFile /dev/null\" -o \"StrictHostKeyChecking no\" -i ~/demokp.pem cirros@$SRV_IP"
	fi
    fi
fi
