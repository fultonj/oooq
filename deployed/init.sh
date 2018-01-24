# Filename:                init.sh
# Description:             Initialize undercloud for deploy
# Time-stamp:              <2018-01-23 20:51:52 fultonj> 
# -------------------------------------------------------
CONNECTION=1
REPO=1
THT=1
ROLES=1
CONTAINERS=1
# -------------------------------------------------------
OVER=192.168.2.2
under=$(ip a s br-ctlplane | grep 192 | awk {'print $2'} | sed s/\\/24//g)
if [[ $under != "192.168.2.1" ]]; then
    echo "Something is wrong with br-ctlplane; exiting."
    ip a s br-ctlplane
    exit 1
fi
if [ ! -f /home/stack/stackrc ]; then 
    echo "/home/stack/stackrc does not exist. Exiting. "
    exit 1
fi
source ~/stackrc
ssh $OVER -l stack "hostname" || (echo "No ssh for stack@over; exiting."; exit 1)
# -------------------------------------------------------
if [ $CONNECTION -eq 1 ]; then
    echo  "Can overcloud reach undercloud Heat API and Swift Server?"
    ssh $OVER -l stack "curl -s 192.168.2.1:8000" | jq .  # should return json
    ssh $OVER -l stack "curl -s 192.168.2.1:8080" # should 404
    echo ""
    echo "404 above is expcted ^"
    echo ""
    echo "overcloud default route should be 192.168.2.1 ..."
    echo ""
    ssh $OVER -l stack "/sbin/ip route | grep default"
    # echo "If necessary, fix with fix with..."
    # echo "ip route add default via 192.168.2.1"
    # ssh $OVER -l stack "echo GATEWAY='192.168.2.1' > /tmp/etc-sysconfig-network"
    # ssh $OVER -l stack "mv /tmp/etc-sysconfig-network /etc/sysconfig/network"
    # ssh $OVER -l stack "sudo /sbin/ip route add default via 192.168.2.1"
    # ssh $OVER -l stack "/sbin/ip route"
fi
# -------------------------------------------------------
if [ $REPO -eq 1 ]; then
    url=https://trunk.rdoproject.org/centos7/current/python2-tripleo-repos-0.0.1-0.20171116021457.15e17a8.el7.centos.noarch.rpm
    ssh $OVER -l stack "sudo yum install -y $url"
    ssh $OVER -l stack "sudo -E tripleo-repos current-tripleo-dev"
    ssh $OVER -l stack "sudo yum repolist"
    ssh $OVER -l stack "sudo yum update -y"
    ssh $OVER -l stack "sudo yum -y install python-heat-agent*"
fi
# -------------------------------------------------------
if [ $THT -eq 1 ]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
    ln -s ~/oooq/deployed/tht ~/tht
fi
# -------------------------------------------------------
if [ $ROLES -eq 1 ]; then
    echo "Generate ~/roles_data.yaml manually"
    # 1. Create good default
    # openstack overcloud roles generate -o ~/roles_data.yaml Controller
    #
    # 2. Compose limited all in one role
    # Replace list under ServicesDefault with list under ControllerServices 
    # from ~/templates/ci/environments/scenario001-multinode-containers.yaml
    #
    # 3. Remove All Ceph services except CephClient
    #
    # 4. Add disable_constraints  
    #echo "  disable_constraints: True" >> ~/roles_data.yaml
fi
# -------------------------------------------------------
if [ $CONTAINERS -eq 1 ]; then
    tag="current-tripleo-rdo"
    openstack overcloud container image prepare \
	--namespace trunk.registry.rdoproject.org/master \
	--tag $tag \
	--env-file ~/docker_registry.yaml
fi
# -------------------------------------------------------
