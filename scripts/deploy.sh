#!/bin/bash

# Deploy script
# staging will go on Digital Ocean
# prod will go on openstack on premice

KEYNAME="ovh"
IMAGE="Debian 8 - Docker"
FLAVOR="vps-ssd-1"
SSHCMD="ssh -i /home/travis/.ssh/ovh_rsa -o StrictHostKeyChecking=no"
#SSHCMD="ssh -i /home/uggla/.ssh/ovh_rsa -o StrictHostKeyChecking=no"
SCPCMD="scp -i /home/travis/.ssh/ovh_rsa"
#SCPCMD="scp -i /home/uggla/.ssh/ovh_rsa"

echo "$1 phase"

cd scripts
source ./openrc.sh
export OS_PASSWORD="$OS_PASSWORD"
openstack server list

echo "Commit: $TRAVIS_COMMIT"

# Build the instances
openstack server create --image "$IMAGE" --flavor "$FLAVOR" --key-name "$KEYNAME" d1-$TRAVIS_COMMIT
openstack server create --image "$IMAGE" --flavor "$FLAVOR" --key-name "$KEYNAME" d2-$TRAVIS_COMMIT
openstack server create --image "$IMAGE" --flavor "$FLAVOR" --key-name "$KEYNAME" d3-$TRAVIS_COMMIT --wait

# Get the ips
while ([[ -z $d1ip ]] && [[ -z $d2ip ]] && [[ -z $d3ip ]])
do
	d1ip=$(openstack server show d1-$TRAVIS_COMMIT -f json | jq -r '.addresses' | awk -F ',' '{print $NF}' | sed -r 's/\s//g')
	d2ip=$(openstack server show d2-$TRAVIS_COMMIT -f json | jq -r '.addresses' | awk -F ',' '{print $NF}' | sed -r 's/\s//g')
	d3ip=$(openstack server show d3-$TRAVIS_COMMIT -f json | jq -r '.addresses' | awk -F ',' '{print $NF}' | sed -r 's/\s//g')
done

echo "Intance:IPs"
echo "d1:$d1ip"
echo "d2:$d2ip"
echo "d3:$d3ip"

# Remove host keys
ssh-keygen -R $d1ip
ssh-keygen -R $d2ip
ssh-keygen -R $d3ip

# Try to connect each instance
#ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
while ([[ -z $outd1 ]] && [[ -z $outd2 ]] && [[ -z $outd3 ]])
do
    outd1=$($SSHCMD debian@$d1ip uname -a)
    outd2=$($SSHCMD debian@$d2ip uname -a)
    outd3=$($SSHCMD debian@$d3ip uname -a)
	sleep 2s
done

# Building small 3 nodes cluster
$SSHCMD debian@$d1ip sudo docker swarm init
jointokencmd=$($SSHCMD debian@$d1ip sudo docker swarm join-token worker)
jointokencmd=$(echo $jointokencmd | awk -F 'command: ' '{print $NF}' | sed -r 's/ \\ / /g')

$SSHCMD debian@$d2ip sudo $jointokencmd
$SSHCMD debian@$d3ip sudo $jointokencmd

# Install docker-compose on master
$SSHCMD debian@$d1ip $(cat << EOF
sudo apt-get update &&
sudo apt-get install -y jq curl &&
sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose &&
sudo chmod +x /usr/local/bin/docker-compose &&
docker-compose --version
EOF
)

# Copy compose file
$SCPCMD cd_staging.sh debian@$d1ip:
$SCPCMD ../docker-compose-v3.yml debian@$d1ip:

# Run application
$SSHCMD debian@$d1ip sudo ./cd_staging.sh
