#!/usr/bin/env bash

source ~/stackrc

time openstack overcloud deploy \
    --templates ~/templates/ \
    --config-download \
    -e ~/templates/environments/config-download-environment.yaml \
    -e ./overrides.yaml
