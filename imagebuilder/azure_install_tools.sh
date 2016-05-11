#! /usr/bin/sudo /bin/bash

# ---
# RightScript Name: Packer Install Azure Tools
# Description: |
#   Install Azure tools for Packer
# Inputs: {}
#
# ...

set -ex

apt-get -y update
apt-get -y install nodejs-legacy npm
# 0.9.3-0.9.13 have various problems
npm install -g azure-cli@0.9.2
