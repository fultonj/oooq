#!/usr/bin/env bash

# experimental

docker ps | grep mistral
docker images | grep mistral

for CON in $(docker ps --filter 'name=mistral' --format "{{.ID}}"); do
    docker stop $CON
    docker rm $CON
done

for CON in $(echo mistral_{api,engine,event_engine,executor}); do    
    echo \#$CON; 
    sudo paunch debug \
	 --file /var/lib/tripleo-config/docker-container-startup-config-step_4.json \
	 --container $CON \
	 --action print-cmd
done  > restart_mistral_helper.sh

# bash restart_mistral_helper.sh
