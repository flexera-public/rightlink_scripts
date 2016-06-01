#!/bin/bash

# ---
# RightScript Name: RL10 Linux Enable Managed Login
# Description: |
#   Install RightScale NSS plugin, and update PAM and SSH configuration to
#   allow SSH connectivity to RightScale accounts.
# Inputs:
#   MANAGED_LOGIN:
#     Input Type: single
#     Category: RightScale
#     Description: To enable or disable managed login.  Default is 'enable'.
#     Required: false
#     Advanced: true
#     Default: text:enable
#     Possible Values:
#       - text:enable
#       - text:disable
# Attachments:
#   - rs-ssh-keys.sh
#   - libnss_rightscale.tgz
# ...

set -e

# Install /usr/local/bin/rs-ssh-keys.sh
echo "Installing /usr/local/bin/rs-ssh-keys.sh"
attachments=${RS_ATTACH_DIR:-attachments}
sudo cp ${attachments}/rs-ssh-keys.sh /usr/local/bin/
sudo chmod 0755 /usr/local/bin/rs-ssh-keys.sh

# Update /etc/ssh/sshd_config with command to obtain user keys
if ! grep --quiet rs-ssh-keys.sh /etc/ssh/sshd_config; then
  # Remove any current AuthorizedKeysCommand and AuthorizedKeysCommandUser entries
  sudo sed -i -e '/AuthorizedKeysCommand\|AuthorizedKeysCommandUser/d' /etc/ssh/sshd_config
  echo "Adding AuthorizedKeysCommand /usr/local/bin/rs-ssh-keys.sh to /etc/ssh/sshd_config"
  sudo bash -c "echo 'AuthorizedKeysCommand /usr/local/bin/rs-ssh-keys.sh' >> /etc/ssh/sshd_config"
  sudo bash -c "echo 'AuthorizedKeysCommandUser nobody' >> /etc/ssh/sshd_config"
  sudo service ssh restart
else
  echo "AuthorizedKeysCommand already setup"
fi

# update pam config to create homedir on login
if [ -e /etc/pam.d/sshd ]; then
  if ! grep pam_mkhomedir /etc/pam.d/sshd; then
    echo "Adding pam_mkhomedir to /etc/pam.d/sshd"
    sudo bash -c "echo 'session required pam_mkhomedir.so skel=/etc/skel/ umask=0022' >> /etc/pam.d/sshd"
  else
    echo "PAM config /etc/pam.d/sshd already contains pam_mkhomedir"
  fi
else
  echo "Don't know how to configure pam for this system!"
  exit 1
fi

# Update nsswitch.conf
if ! grep rightscale /etc/nsswitch.conf; then
  echo "Configuring /etc/nsswitch.conf"
  sudo sed -i '/^\(passwd\|group\|shadow\)/ s/$/ rightscale/' /etc/nsswitch.conf
else
  echo "/etc/nsswitch.conf already configured"
fi

# Install NSS plugin libraries
if grep -iq "id=coreos" /etc/os-release 2> /dev/null; then
  lib_dir="/opt/lib"
else
  lib_dir="/usr/local/lib"
fi
sudo tar --no-same-owner -xzvf ${attachments}/libnss_rightscale.tgz -C ${lib_dir}
sudo bash -c "echo ${lib_dir} > /etc/ld.so.conf.d/rightscale.conf"
sudo ldconfig

# Adding rs_login:state=user tag
rsc --rl10 cm15 multi_add /api/tags/multi_add resource_hrefs[]=$RS_SELF_HREF tags[]=rs_login:state=user
