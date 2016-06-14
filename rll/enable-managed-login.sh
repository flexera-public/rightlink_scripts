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

# Entry for sshd_config
ssh_config_entry="AuthorizedKeysCommand /usr/local/bin/rs-ssh-keys.sh"

# Verify prerequisites before making changes
if cut --delimiter=# --fields=1 /etc/ssh/sshd_config | grep -v "${ssh_config_entry}" | grep --quiet "AuthorizedKeysCommand\b"; then
  echo "AuthorizedKeysCommand already in use. This is required to continue - exiting without configuring managed login"
  exit 1
fi
if [ ! -e /etc/pam.d/sshd ]; then
  echo "Unable to determine location of required PAM sshd configuration - exiting without configuring managed login"
  exit 1
fi

# Install /usr/local/bin/rs-ssh-keys.sh
echo "Installing /usr/local/bin/rs-ssh-keys.sh"
attachments=${RS_ATTACH_DIR:-attachments}
sudo cp ${attachments}/rs-ssh-keys.sh /usr/local/bin/
sudo chmod 0755 /usr/local/bin/rs-ssh-keys.sh

# Update /etc/ssh/sshd_config with command to obtain user keys
if cut --delimiter=# --fields=1 /etc/ssh/sshd_config | grep --quiet "${ssh_config_entry}"; then
  echo "AuthorizedKeysCommand already setup"
else
  echo "Adding AuthorizedKeysCommand /usr/local/bin/rs-ssh-keys.sh to /etc/ssh/sshd_config"
  sudo bash -c "echo '${ssh_config_entry}' >> /etc/ssh/sshd_config"

  # OpenSSH version 6.2 and higher uses and requires AuthorizedKeysCommandUser
  # sshd does not have a version flag, but it does give a version on its error message for invalid flag
  sshd_version=`sshd --bogus-flag 2>&1 | grep "^OpenSSH" | cut --delimiter=' ' --fields=1 | cut --delimiter='_' --fields=2`
  if [[ "$(printf "$sshd_version\n6.2" | sort --version-sort | tail --lines=1)" == "$sshd_version" ]]; then
    sudo bash -c "echo 'AuthorizedKeysCommandUser nobody' >> /etc/ssh/sshd_config"
  else
    echo "ssh version not current enought to use AuthorizedKeysCommandUser config"
  fi

  # Determine if service name is ssh or sshd
  ssh_service_status=`sudo service ssh status 2>/dev/null` || true
  if [[ "$ssh_service_status" == "" ]]; then
    ssh_service_name='sshd'
  else
    ssh_service_name='ssh'
  fi

  sudo service ${ssh_service_name} restart
fi

# Create /etc/sudoers.d/90-rightscale-sudo-users
if [ -e /etc/sudoers.d/90-rightscale-sudo-users ]; then
  echo "Sudoers file already exists"
else
  echo "Creating sudoers file"
  sudo bash -c "printf '# Members of the rightscale_sudo group may gain root privileges\n%%rightscale_sudo ALL=(ALL) SETENV:NOPASSWD:ALL\n' > /etc/sudoers.d/90-rightscale-sudo-users"
  sudo chmod 0440 /etc/sudoers.d/90-rightscale-sudo-users
fi

# Update pam config to create homedir on login
if cut --delimiter=# --fields=1 /etc/pam.d/sshd | grep --quiet pam_mkhomedir; then
  echo "PAM config /etc/pam.d/sshd already contains pam_mkhomedir"
else
  echo "Adding pam_mkhomedir to /etc/pam.d/sshd"
  sudo bash -c "printf '# Added by RightScale Managed Login script\nsession required pam_mkhomedir.so skel=/etc/skel/ umask=0022\n' >> /etc/pam.d/sshd"
fi

# Update nsswitch.conf
if cut --delimiter=# --fields=1 /etc/nsswitch.conf | grep --quiet rightscale; then
  echo "/etc/nsswitch.conf already configured"
else
  echo "Configuring /etc/nsswitch.conf"
  sudo sed -i '/^\(passwd\|group\|shadow\)/ s/$/ rightscale/' /etc/nsswitch.conf
fi

# Install NSS plugin library. This has been designed to overwrite existing library.
if grep -iq "id=coreos" /etc/os-release 2> /dev/null; then
  lib_dir="/opt/lib"
else
  lib_dir="/usr/local/lib"
fi
sudo tar --no-same-owner -xzf ${attachments}/libnss_rightscale.tgz -C ${lib_dir}
sudo bash -c "echo ${lib_dir} > /etc/ld.so.conf.d/rightscale.conf"
sudo ldconfig

# Determine location of rsc
[[ -e /usr/local/bin/rsc ]] && rsc=/usr/local/bin/rsc || rsc=/opt/bin/rsc

# Adding rs_login:state=user tag
$rsc --rl10 cm15 multi_add /api/tags/multi_add resource_hrefs[]=$RS_SELF_HREF tags[]=rs_login:state=user
