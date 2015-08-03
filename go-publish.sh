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

# Set our test image and container names.
TEST_IMAGE="$GO_PIPELINE_NAME-$GO_PIPELINE_COUNTER-test"
TEST_CONTAINER="$TEST_IMAGE-container"

# Build our container.
docker build -t "$TEST_IMAGE" .

# Run our docker container (without printing).
set +o xtrace
echo "(Running docker container)"
docker run \
    -e ECS_COMPOSE_BUILD_NUMBER="$GO_PIPELINE_COUNTER" \
    -e RUBYGEMS_AUTH="$PUBLIC_FARADAYIO_RUBYGEMS_AUTH" \
    --name "$TEST_CONTAINER" \
    --rm \
    "$TEST_IMAGE"
set -o xtrace

# Clean up our image now that we no longer need it.
docker rmi "$TEST_IMAGE"


