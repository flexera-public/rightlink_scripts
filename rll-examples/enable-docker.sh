#!/bin/bash -e

# ---
# RightScript Name: RL10 Linux Enable Docker
# Description: |
#   Install Docker and enable RightLink Docker features.
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
#

# Install docker
curl -sSL https://get.docker.com/ | sh

# Add users to docker group, allowing access to docker.sock and docker daemon
sudo usermod -aG docker rightscale
sudo usermod -aG docker rightlink
# Unfortunatly, since we started rightlink _before_ installing docker, the running rightlink process
# is not aware of the new group it belongs to, so workaround is to change group of docker.sock
sudo chgrp rightlink /var/run/docker.sock

# Current process must know that user is now in docker group
newgrp docker

# Obtain local auth info
. <(sudo cat /var/run/rightlink/secret)

# Enable docker support
curl -sS -H "X-Rll-Secret: $RS_RLL_SECRET" -X PUT "http://localhost:${RS_RLL_PORT}/rll/docker/control?enable_docker=$RIGHTLINK_DOCKER"
