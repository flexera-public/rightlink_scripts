#!/bin/bash

# ---
# RightScript Name: RL10 Linux Enable Docker Support (Beta)
# Description: |
#   Enable RightLink Docker features if docker is installed
# Inputs:
#   RIGHTLINK_DOCKER:
#     Input Type: single
#     Category: RightLink
#     Description: |
#       Level of Docker integration for RightLink: monitoring + tagging; tagging; nothing.
#     Required: false
#     Advanced: true
#     Default: text:all
#     Possible Values:
#       - text:all
#       - text:tags
#       - text:none
# ...

set -e

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

if ! command_exists docker; then
  echo "Docker is not installed - skipping enabling of docker support"
  exit
fi

# Enable docker support
rsc rl10 update /rll/docker/control "enable_docker=$RIGHTLINK_DOCKER"
