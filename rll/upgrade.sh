#! /bin/bash -e

# Will compare current version of rightlink 'running' with latest version provided from 'upgrades'
# file. If they differ, will update to latest version.  Note that latest version can be an older version
# if a downgrade is best.

UPGRADES_FILE_LOCATION=${UPGRADES_FILE_LOCATION:-"https://rightlink.rightscale.com/rightlink/upgrades"}

upgrade_rightlink() {

  # Use 'logger' here instead of 'echo' since stdout from this is not sent to
  # audit entries as RightLink is down for a short time during the upgrade process.

  res=$(/usr/local/bin/rsc rl10 upgrade /rll/upgrade exec=${rl_bin}-new 2>/dev/null || true)
  if [[ "$res" =~ successful ]]; then
    # Delete the old version if it exists from the last upgrade.
    sudo rm -rf ${rl_bin}-old
    # Keep the old version in case of issues, ie we need to manually revert back.
    sudo mv ${rl_bin} ${rl_bin}-old
    sudo cp ${rl_bin}-new ${rl_bin}
    logger -t rightlink "rightlink updated"
  else
    logger -t rightlink "Error: ${res}"
    exit 1
  fi
  # Check updated version in production by connecting to local proxy
  # The update takes a few seconds so retries are done.
  for retry_counter in {1..5}; do
    # The auth information is updated on an upgrade.  Continue to source the
    # auth file to grab the updated auth info once RightLink has restarted.
    new_installed_version=$(/usr/local/bin/rsc --x1 .version rl10 index proc 2>/dev/null || true)
    if [[ "$new_installed_version" == "$desired" ]]; then
      logger -t rightlink "New version active - ${new_installed_version}"
      break
    else
      logger -t rightlink "Waiting for new version to become active."
      sleep 2
    fi
  done
  if [[ "$new_installed_version" != "$desired" ]]; then
    logger -t rightlink "New version does not appear to be desired version: ${new_installed_version}"
    exit 1
  fi

  # Report to audit entry that RightLink ugpraded.
  instance_href=$(/usr/local/bin/rsc --rl10 --x1 ':has(.rel:val("self")).href' cm15 index_instance_session /api/sessions/instance 2>/dev/null)
  if [[ -n "$instance_href" ]]; then
    audit_entry_href=$(/usr/local/bin/rsc --rl10 --xh 'location' cm15 create /api/audit_entries "audit_entry[auditee_href]=${instance_href}" \
                     "audit_entry[detail]=RightLink updated to '${new_installed_version}'" "audit_entry[summary]=RightLink updated" 2>/dev/null)
    if [[ -n "$audit_entry_href" ]]; then
      logger -t rightlink "audit entry created at ${audit_entry_href}"
    else
      logger -t rightlink "failed to create audit entry"
    fi
  else
    logger -t rightlink "unable to obtain instance href for audit entries"
  fi
  exit 0
}

# Query RightLink info
json=$(/usr/local/bin/rsc rl10 index /rll/proc)

# Detemine bin_path
rl_bin=$(echo "$json" | /usr/local/bin/rsc --x1 .bin_path json)

# Determine current version of rightlink
current_version=$(echo "$json" | /usr/local/bin/rsc --x1 .version json)

if [[ -z "$current_version" ]]; then
  echo "Can't determine current version of RightLink"
  exit 1
fi

# Fetch information about what we should become. The "upgrades" file consists of lines formatted
# as "current_version:upgradeable_new_version". If the "upgrades" file does not exist,
# or if the current version is not in the file, no upgrade is done.
re="^\s*${current_version}\s*:\s*(\S+)\s*$"
match=`curl --silent --show-error --retry 3 ${UPGRADES_FILE_LOCATION} | egrep ${re} || true`
if [[ "$match" =~ $re ]]; then
  desired="${BASH_REMATCH[1]}"
else
  echo "Cannot determine latest version from upgrade file"
  echo "Tried to match /^${current_version}:/ in ${UPGRADES_FILE_LOCATION}"
  exit 0
fi

if [[ "$desired" == "$current_version" ]]; then
  echo "RightLink is already up-to-date (current=${current_version})"
  exit 0
fi

echo "RightLink needs update:"
echo "  from current=${current_version}"
echo "  to   desired=${desired}"

echo "downloading RightLink version '${desired}'"

# Download new version
cd /tmp
sudo rm -rf rightlink rightlink.tgz
curl --silent --show-error --retry 3 --output rightlink.tgz https://rightlink.rightscale.com/rll/${desired}/rightlink.tgz
tar zxf rightlink.tgz || (cat rightlink.tgz; exit 1)

# Check downloaded version
sudo mv rightlink/rightlink ${rl_bin}-new
echo "checking new version"
new=`${rl_bin}-new -version | awk '{print $2}'`
if [[ "$new" == "$desired" ]]; then
  echo "new version looks right: ${new}"
  echo "restarting RightLink to pick up new version"
  # Fork a new task since this main process is started
  # by RightLink and we are restarting it.
  upgrade_rightlink &
else
  echo "Updated version does not appear to be desired version: ${new}"
  exit 1
fi
