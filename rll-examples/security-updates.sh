#! /bin/bash -e

# ---
# RightScript Name: RL10 Linux Security Updates
# Description: Installs security updates
# ...
#

# Run sudo apt-get|yum with retries if errors occur.
# $@: full APT-GET(8) or yum(8) command
#
function package_handler() {
  # Setting config variables for this function
  retries=5
  wait_time=10

  # Check that the correct package application is being called
  if [ "$1" != "apt-get" ] && [ "$1" != "yum" ]; then
    echo "ERROR: invalid package command: $1"
    exit 1
  fi

  while [ $retries -gt 0 ]; do
    # Reset this variable before every iteration to be checked if changed
    issue_running_command=false
    sudo $@ || { issue_running_command=true; }
    if [ "$issue_running_command" = true ]; then
      (( retries-- ))
      echo "Error occurred - will retry shortly"
      sleep $wait_time
    else
      # Break out of loop since command was successful.
      break
    fi
  done

  # Check if issue running command still existed after all retries
  if [ "$issue_running_command" = true ]; then
    echo "ERROR: Unable to run package application."
    return 1
  fi
}

# Ubuntu/Debian
if [[ -d /etc/apt ]]; then
  # Autopopulate this ENV var for all subsequent scripts
  /usr/local/bin/rsc rl10 update /rll/env/DEBIAN_FRONTEND payload=noninteractive
  export DEBIAN_FRONTEND=noninteractive
  time package_handler apt-get -qy update
  time package_handler apt-get -qy install unattended-upgrades
elif [[ -e /etc/redhat-release || -n "$(grep Amazon /etc/system-release 2>/dev/null)" ]]; then
  # RHEL/CentOS/Amazon Linux
  time package_handler yum -y install yum-plugin-security
  # update-minimal may fail on RHEL7, see https://bugzilla.redhat.com/show_bug.cgi?id=1048584
  time package_handler yum -y --security update-minimal || time package_handler yum -y --security update
else
  echo "WARNING: security updates not installed as we could not determine your OS distro."
fi
