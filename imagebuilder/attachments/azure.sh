#!/bin/bash -ex

[ -f /etc/waagent.conf ] && sudo sed -i 's#Provisioning.Enabled=y#Provisioning.Enabled=n#' /etc/waagent.conf

[ -f /usr/share/oem/bin/waagent ] && sudo sed -i 's%#!/usr/bin/env python%#!/usr/share/oem/python/bin/python%g' /usr/share/oem/bin/waagent

# The remaining tasks are only for CentOS
which yum &> /dev/null || exit 0
sudo ln -sf /etc/init.d/waagent /etc/init.d/walinuxagent
echo '$SystemLogRateLimitInterval 0' > /tmp/etc-rsyslog.d-10-removeratelimit.conf && sudo install -m 0644 /tmp/etc-rsyslog.d-10-removeratelimit.conf /etc/rsyslog.d/10-removeratelimit.conf && rm -f /tmp/etc-rsyslog.d-10-removeratelimit.conf
sudo sync