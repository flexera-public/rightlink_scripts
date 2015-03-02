#!/bin/bash

# Add entry in /etc/cron.d/ to daily check and excute an upgrade for rightlink.

# -e will immediatly exit out of script at point of error
# -x print each command to stdout before exxecuting it
set -ex

cron_file='/etc/cron.d/rightlink_upgrade'

# Grab toggle option to disable
if [[ "$DISABLE_AUTO_UPGRADE" == 'true' ]]; then
  if [ -e ${cron_file} ]; then
    rm -f ${cron_file}
    echo "Automatic upgrade disabled"
  else
    echo "Automatic upgrade never enabled - no actions done"
  fi
else
  # If cron file already exists, will recreate it with new random times.
  [ -e ${cron_file} ] && echo "Recreating cron entry"

  upgrade_command='add_rs_run_recipe_script_here'

  # Random hour 0-23
  cron_hour=$[ $RANDOM % 24 ]

  # Random minute 0-59
  cron_minute=$[ $RANDOM % 60 ]

  umask 077

  echo "${cron_minute} ${cron_hour} * * * root ${upgrade_command}" > ${cron_file}

  # Set perms regardless of umask since the file could be overwritten with existing perms.
  chmod 0600 /etc/cron.d/${cron_file}

  echo 'Automatic upgrade enabled.'
fi
