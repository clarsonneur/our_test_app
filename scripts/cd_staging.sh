#!/bin/bash

# Script to run the CNA as docker services on swarm

#
# You need to provide your Registry address here:
#REGISTRY=uggla
REGISTRY=uggla
APPNAME=ourtestapp
MYSQL_ROOT_PASSWORD=toto
MYSQL_DATABASE=prestashop
MYSQL_USER=prestashop
MYSQL_PASSWORD=prestashop1234
W2_APIKEY=blakey
W2_TO=machin@bidule.com
W2_DOMAIN=domain


# Patch docker-compose-v3.yaml to pass our variables
sed -i "s/##MYSQL_ROOT_PASSWORD##/$MYSQL_ROOT_PASSWORD/" docker-compose-v3.yml
sed -i "s/##MYSQL_DATABASE##/$MYSQL_DATABASE/" docker-compose-v3.yml
sed -i "s/##MYSQL_USER##/$MYSQL_USER/" docker-compose-v3.yml
sed -i "s/##MYSQL_PASSWORD##/$MYSQL_PASSWORD/" docker-compose-v3.yml
sed -i "s/##W2_APIKEY##/$W2_APIKEY/" docker-compose-v3.yml
sed -i "s/##W2_TO##/$W2_TO/" docker-compose-v3.yml
sed -i "s/##W2_DOMAIN##/$W2_DOMAIN/" docker-compose-v3.yml
sed -i "s/##REGISTRY##/$REGISTRY/" docker-compose-v3.yml
sed -i "s/##REGISTRY##/$REGISTRY/" docker-compose-v3.yml
sed -i "s/cloudnativeapp/$APPNAME/" docker-compose-v3.yml

# Start vizualizer on port 8080
docker ps | grep visualizer > /dev/null 2>&1
if [ $? -ne 0 ]; then
    docker ps -a | grep visualizer && docker rm visualizer
    docker run -it -d -p 8080:8080 $ENVOPT -v /var/run/docker.sock:/var/run/docker.sock --name visualizer dockersamples/visualizer
fi

docker stack deploy -c docker-compose-v3.yml cna
sleep 5
docker service ls
