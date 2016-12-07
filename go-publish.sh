#!/bin/sh
#
# DEVELOPMENT ONLY: Called from a GoCD continuous integration pipeline to
# automatically publish pre-release builds of this gem when it changes.
#
# We build inside a docker container to make sure that we have the correct
# authentication credentials and that we're totally isolated.

# Standard paranoia: Exit on errors or undefined variables, and print all
# commands run.
set -e
set -u
set -o xtrace

IMAGE="$GO_PIPELINE_NAME-$GO_PIPELINE_COUNTER"
CONTAINER="$IMAGE-run"

docker build -t $IMAGE .

rm -rf pkg

set +o xtrace

docker run \
    -e ECS_COMPOSE_BUILD_NUMBER="$GO_PIPELINE_COUNTER" \
    -e RUBYGEMS_AUTH="$PUBLIC_FARADAYIO_RUBYGEMS_AUTH" \
    --name $CONTAINER \
    $IMAGE
docker cp $CONTAINER:/gem/pkg pkg
docker rm -f $CONTAINER

set -o xtrace

docker rmi $IMAGE
