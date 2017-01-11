#!/usr/bin/env bash
# Filename:                run-add-disks.sh
# Description:             scp/run add-disks.sh as stack
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-01-10 21:54:46 jfulton> 
# -------------------------------------------------------
SSH_ENV=~/.quickstart/ssh.config.ansible

echo "Installing add-disks.sh in stack@virthost's home"
scp -F $SSH_ENV add-disks.sh stack@virthost:/home/stack/

echo "Running add-disks.sh as stack@virthost"
ssh -F $SSH_ENV stack@virthost "bash add-disks.sh"
