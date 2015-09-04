#! /bin/bash -e

# ---
# RightScript Name: RL10 Linux Security Updates
# Description: Installs security updates
# ...
#

# Run passed-in command with retries if errors occur.
#
# $@: full line command
#
function retry_command() {
  # Setting config variables for this function
  retries=5
  wait_time=10

  while [ $retries -gt 0 ]; do
    # Reset this variable before every iteration to be checked if changed
    issue_running_command=false
    $@ || { issue_running_command=true; }
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
    echo "ERROR: Unable to run: '$@'"
    return 1
  fi
}

# Ubuntu/Debian
if [[ -d /etc/apt ]]; then
  # Autopopulate this ENV var for all subsequent scripts
  /usr/local/bin/rsc rl10 update /rll/env/DEBIAN_FRONTEND payload=noninteractive
  export DEBIAN_FRONTEND=noninteractive
  time retry_command sudo apt-get -qy update
  time retry_command sudo apt-get -qy install unattended-upgrades
elif [[ -e /etc/redhat-release || -n "$(grep Amazon /etc/system-release 2>/dev/null)" ]]; then
  # RHEL/CentOS/Amazon Linux
  time retry_command sudo yum -y install yum-plugin-security
  # update-minimal may fail on RHEL7, see https://bugzilla.redhat.com/show_bug.cgi?id=1048584
  time retry_command sudo yum -y --security update-minimal || time retry_command sudo yum -y --security update
else
  echo "WARNING: security updates not installed as we could not determine your OS distro."
fi
