#!/bin/bash

# Add entry in /etc/cron.d/ to daily check and excute an upgrade for rightlink.

# -e will immediatly exit out of script at point of error
set -e

cron_file='/etc/cron.d/rightlink_upgrade'
exec_file='/usr/local/bin/rightlink_check_upgrade'

# Grab toggle option to disable
if [[ "$DISABLE_AUTO_UPGRADE" == 'true' ]]; then
  if [ -e ${cron_file} ]; then
    rm -f ${cron_file}
    echo "Automatic upgrade disabled"
  else
    echo "Automatic upgrade never enabled - no action done"
  fi
else
  # If cron file already exists, will recreate it with new random times.
  [ -e ${cron_file} ] && echo "Recreating cron entry"

  # Generate executable script to run by cron
  cat > ${exec_file} << 'EOF'
#!/bin/bash

source /var/run/rll-secret
curl --silent --show-error --get --globoff --fail --request POST --header X-RLL-Secret:$RS_RLL_SECRET \
  http://127.0.0.1:$RS_RLL_PORT/rll/run/recipe --data-urlencode "recipe=rll::upgrade"
EOF

  # Random hour 0-23
  cron_hour=$[ $RANDOM % 24 ]

  # Random minute 0-59
  cron_minute=$[ $RANDOM % 60 ]

  umask 077

  echo "${cron_minute} ${cron_hour} * * * root ${exec_file}" > ${cron_file}

  # Set perms regardless of umask since the file could be overwritten with existing perms.
  chmod 0600 ${cron_file}

  echo 'Automatic upgrade enabled.'
fi
