#!/usr/bin/env bash
source ~/stackrc
openstack stack delete overcloud --yes --wait
