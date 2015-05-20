#! /bin/bash -e

# Install security updates

# Ubuntu/Debian
if [[ -d /etc/apt ]]; then
  # Autopopulate this ENV var for all subsequent scripts
  /usr/local/bin/rsc rl10 update /rll/env/DEBIAN_FRONTEND payload=noninteractive
  export DEBIAN_FRONTEND=noninteractive
  time sudo apt-get -qy update
  time sudo apt-get -qy install unattended-upgrades
elif [[ -e /etc/redhat-release || -n "$(grep Amazon /etc/system-release 2>/dev/null)" ]]; then
  # RHEL/CentOS/Amazon Linux
  time sudo yum -y install yum-plugin-security
  # update-minimal may fail on RHEL7, see https://bugzilla.redhat.com/show_bug.cgi?id=1048584
  time sudo yum -y --security update-minimal || time sudo yum -y --security update
else
  echo "WARNING: security updates not installed as we could not determine your OS distro."
fi
