#!/bin/bash

# Push images to docker hub

ACCOUNT=uggla

echo "Pushing image to docker hub"

docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"

for i in $(docker images | grep ourtestapp | awk '{print $1}')
do
    echo "Tagging and pushing image $i..."
    docker tag $i $ACCOUNT/$i:$TRAVIS_COMMIT
    docker push $ACCOUNT/$i &
done

wait
