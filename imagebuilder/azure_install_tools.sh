#! /usr/bin/sudo /bin/bash

set -ex

apt-get -y update
apt-get -y install nodejs-legacy npm
# 0.9.3-0.9.13 have various problems
npm install -g azure-cli@0.9.2
