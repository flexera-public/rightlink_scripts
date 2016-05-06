#!/bin/bash -ex

[ -f /etc/os-release ] && source /etc/os-release
[ "$ID" == "coreos" ] && echo "Skipping on Core-OS" && exit 0
sudo yum install -y cloud-init || sudo apt-get -y install cloud-init python-serial
sudo sync
sudo ls /etc/cloud