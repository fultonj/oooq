#!/usr/bin/env bash
# In Rocky and newer overcloud deployments have been failing
# during ansible's NTP configuration because they are unable
# to reach Internet. Run the following on the undercloud, as
# set up by quickstart, so that eth0 (192.168.23.0/24) routes
# packets which come into the gateway of the deployment
# network (192.168.24.1/24) or simulated vlan10 external 
# network (10.0.0.1/24) out to Internet.

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
