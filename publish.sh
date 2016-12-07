#!/bin/bash
#
# DEVELOPMENT ONLY. Run from our Dockerfile.

# Standard paranoia: Exit on errors or undefined variables, and print all
# commands run.
set -e
set -u
set -o xtrace

# Log into Rubygems.
mkdir -p ~/.gem
echo "(Logging into rubygems)"
set +o xtrace
curl -u faradayio:"$RUBYGEMS_AUTH" https://rubygems.org/api/v1/api_key.yaml > \
    ~/.gem/credentials
set -o xtrace
chmod 0600 ~/.gem/credentials

# Test our gem.
rspec

mkdir -p pkg
gem build ecs_compose.gemspec
mv *.gem pkg/
gem push pkg/*.gem
