#!/usr/bin/env bash
echo "Configuring ~/.ssh/config to not prompt for non-matching keys and not manage keys via known_hosts"
cat /dev/null > ~/.ssh/config
echo "StrictHostKeyChecking no" >> ~/.ssh/config
echo "UserKnownHostsFile=/dev/null" >> ~/.ssh/config
echo "LogLevel ERROR" >> ~/.ssh/config
chmod 0600 ~/.ssh/config
chmod 0700 ~/.ssh/
