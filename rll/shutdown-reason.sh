#! /bin/bash
echo ===== DECOMMISSIONING =====

if [[ `/sbin/init --version` =~ upstart ]]; then
  echo using upstart
  # We look at the runlevel, although there's probably a more upstart-ish way of doing this?
  echo Runlevel is `runlevel`
  [[ `runlevel | cut -d ' ' -f 2` =~ 0|1|S|6 ]] && echo "The system is going down" || echo "not going down? huh?"
  [[ `runlevel | cut -d ' ' -f 2` == "6" ]] && echo "-> rebooting" || echo "-> not rebooting"
  [[ `runlevel | cut -d ' ' -f 2` == "0" ]] && echo "-> shutting down" || echo "-> not shutting down"
elif [[ `systemctl` =~ -\.mount ]]; then
  echo using systemd
  # Don't look at the runlevel, it doesn't work, we need to figure out which target we're heading for
  /usr/bin/systemctl list-jobs | egrep -q 'shutdown.target.*start' && echo "The system is going down" || echo "not going down? huh?"
  /usr/bin/systemctl list-jobs | egrep -q 'reboot.target.*start' && echo "-> rebooting" || echo "-> not rebooting"
  /usr/bin/systemctl list-jobs | egrep -q 'halt.target.*start' && echo "-> halting" || echo "-> not halting"
  /usr/bin/systemctl list-jobs | egrep -q 'poweroff.target.*start' && echo "-> shutting down" || echo "-> not shutting down"
  echo "====="
  /usr/bin/systemctl list-jobs
  echo "====="
  /usr/bin/systemctl list-units
  echo "====="
  echo Runlevel is `runlevel`
elif [[ -f /etc/init.d/cron && ! -h /etc/init.d/cron ]]; then
  echo using sysv-init
  # The current runlevel should tell us what's up
  echo Runlevel is `runlevel`
  [[ `runlevel | cut -d ' ' -f 2` =~ 0|1|S|6 ]] && echo "The system is going down" || echo "not going down? huh?"
  [[ `runlevel | cut -d ' ' -f 2` == "6" ]] && echo "-> rebooting" || echo "-> not rebooting"
  [[ `runlevel | cut -d ' ' -f 2` == "0" ]] && echo "-> shutting down" || echo "-> not shutting down"
else
  echo cannot tell which init system we are using
  # Default to using the current runlevel...
  echo Runlevel is `runlevel`
  [[ `runlevel | cut -d ' ' -f 2` =~ 0|1|S|6 ]] && echo "The system is going down" || echo "not going down? huh?"
  [[ `runlevel | cut -d ' ' -f 2` == "6" ]] && echo "-> rebooting" || echo "-> not rebooting"
  [[ `runlevel | cut -d ' ' -f 2` == "0" ]] && echo "-> shutting down" || echo "-> not shutting down"
fi
