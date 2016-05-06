#!/bin/bash -ex
sudo rm -rf /var/lib/cloud/ /tmp/*
sudo rm -f /var/log/cloud-init* /etc/udev/rules.d/70-persistent-net.rules
sudo find /root -name authorized_keys -type f -exec rm -f {} \;
sudo find /home -name authorized_keys -type f -exec rm -f {} \;
sudo find /var/log -type f -exec cp /dev/null {} \;
history -c
sync