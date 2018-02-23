#!/usr/bin/env bash

if [[ ! -d ~/.ssh ]]; then mkdir  ~/.ssh; fi
if [[ ! -f ~/.ssh/config ]]; then
    echo StrictHostKeyChecking no > ~/.ssh/config
    chmod 0600 ~/.ssh/config
    rm -f ~/.ssh/known_hosts 2> /dev/null
    ln -s /dev/null ~/.ssh/known_hosts
fi
