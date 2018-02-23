#!/usr/bin/env bash
source ~/stackrc
time openstack stack delete overcloud --yes --wait
