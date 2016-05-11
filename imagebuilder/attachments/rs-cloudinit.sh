#!/bin/bash -x

if which yum &> /dev/null; then
  set -e
  echo "Configuring for Enterprise Linux"
  distro=$(sed -n 's/^distroverpkg=//p' /etc/yum.conf)
  distro=${distro:-redhat-release}
  rel=$(rpm -q --qf "%{version}" -f /etc/$distro)
  ver=${rel/[^0-9]*/}
  cat <<EOF > /tmp/etc-yum.repos.d-RightScale-epel.repo
[rightscale-epel]
name=RightScale Software
baseurl=http://mirror.rightscale.com/rightscale_software/centos/$ver/x86_64/archive/latest/
enabled=1
gpgcheck=1
gpgkey=http://mirror.rightscale.com/rightlink/rightscale.pub
priority=1
EOF
  sudo install -m 0600 /tmp/etc-yum.repos.d-RightScale-epel.repo /etc/yum.repos.d/RightScale-epel.repo && rm -f /tmp/etc-yum.repos.d-RightScale-epel.repo
  which subscription-manager &> /dev/null && subscription-manager repos --enable=rhel-$ver-server-rh-common-rpms
  sudo yum -y install cloud-init
  sudo rm -f /etc/yum.repos.d/RightScale-epel.repo
elif which apt-get &> /dev/null; then
  set -e
  echo "Configuring for Ubuntu"
  if [ `lsb_release -rs` == "12.04" ]; then
    cat <<EOF > /etc/apt/preferences.d/rightscale-cloud-init-pin-1001
Package: cloud-init
Pin: version 0.7.2*
Pin-Priority: 1001
EOF
  fi

  wget -O - http://mirror.rightscale.com/rightlink/rightscale.pub | sudo apt-key add -
  release=`lsb_release -cs`
  echo "deb [arch=amd64] http://mirror.rightscale.com/rightscale_software_ubuntu/latest $release main" > /etc/apt/sources.list.d/rightscale_extra.sources.list
  sudo apt-get -y update
  sudo apt-get -y install cloud-init python-serial
  sudo rm -f /etc/apt/sources.list.d/rightscale_extra.sources.list
  sudo apt-get -y update
else
  echo "Unknown OS"
  exit 0
fi

sudo sync
sudo ls /etc/cloud