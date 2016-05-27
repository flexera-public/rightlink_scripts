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
# Attachements: []
# ...

set -e

# Install /usr/local/bin/rs-ssh-keys
rs-ssh-key-exec=$(cat <<"EOF"
#!/bin/bash
set -e
user=$1
line=`grep -E "^$user:|^[0-9a-z_\-]*:$user:" /tmp/login_policy` || true
[[ "$line" == "" ]] && exit 0
read preferred_name unique_name <<< $(echo $line | cut -d: -f1,2 --output-delimiter=' ')
# $preferred_name and $unique_name can be used for logging
echo $line | cut -d: -f7- | tr : "\n"
EOF
)
sudo bash -c "echo ${rs-ssh-key-exec} > /usr/local/bin/rs-ssh-keys"
sudo chmod 0755 /usr/local/bin/rs-ssh-keys

# Update /etc/ssh/sshd_config with command to obtain user keys
sudo bash -c "echo 'AuthorizedKeysCommand /usr/local/bin/rs-ssh-keys' >> /etc/ssh/sshd_config"
sudo bash -c "echo 'AuthorizedKeysCommandUser nobody' >> /etc/ssh/sshd_config"

# update pam config to create homedir on login
sudo bash -c "echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" >> /etc/pam.d/sshd"

# TODO: Install NSS plugin

# TODO: Adding rs_login:state=user tag
