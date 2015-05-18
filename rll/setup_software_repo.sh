#! /bin/bash -e

# Install security updates
# Set up needed external repositories for collectd.

#
# Ubuntu / Debian
#
if [[ -d /etc/apt ]]; then
  # Autopopulate this ENV var for all subsequent scripts
  /usr/local/bin/rsc rl10 update /rll/env/DEBIAN_FRONTEND payload=noninteractive
  export DEBIAN_FRONTEND=noninteractive
  time sudo apt-get -qy update
  time sudo apt-get -qy install unattended-upgrades
#
# CentOS
#
elif [[ `cat /etc/redhat-release` =~ ^CentOS.*\ ([0-9])\. ]]; then
  ver="${BASH_REMATCH[1]}"
  case "$ver" in
  6)
    if ! yum list installed "epel-release-6*"; then
      sudo rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
      sudo sed -i 's/https/http/' /etc/yum.repos.d/epel.repo # versions of 6.x have trouble with https...
    fi
    ;;
  7)
    if ! yum list installed "epel-release-7*"; then
      sudo rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
    fi
    ;;
  esac
  time sudo yum -y install yum-plugin-security
  time sudo yum -y --security update-minimal

#
# RedHat
#
elif [[ `cat /etc/redhat-release` =~ ^Red\ Hat.*\ ([0-9])\. ]]; then
  ver="${BASH_REMATCH[1]}"
  case "$ver" in
  6)
    if ! yum list installed "epel-release-6*"; then
      sudo rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    fi
    time sudo yum -y install yum-plugin-security
    time sudo yum -y --security update-minimal
    ;;
  7)
    if ! yum list installed "epel-release-7*"; then
      sudo rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
    fi
    time sudo yum -y install yum-plugin-security
    # update-minimal fails on RHEL7, see https://bugzilla.redhat.com/show_bug.cgi?id=1048584
    time sudo yum -y --security update
    ;;
  esac

#
# AWS-Linux
#
elif [[ `cat /etc/system-release` =~ ^Amazon\ Linux.*\ ([0-9]+)\. ]]; then
  time sudo yum -y install yum-plugin-security
  # update-minimal fails on RHEL7, see https://bugzilla.redhat.com/show_bug.cgi?id=1048584
  time sudo yum -y --security update
fi
