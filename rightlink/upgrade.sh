#! /bin/bash

# Will compare current version of rightlink 'running' with latest version provided from 'upgrades'
# file. If they differ, will update to latest version.  Note that latest version can be an older version
# if a downgrade is best.

# -e will immediatly exit out of script at point of error
set -e

RLL_SECRET=/var/run/rightlink-secret

upgrade_rightlink() {

  # Use 'logger' here instead of 'echo' since stdout from this is not sent to
  # audit entries as RightLink is down for a short time during the upgrade process.

  source ${RLL_SECRET}
  res=`curl --silent --show-error --request POST --header X-RLL-Secret:$RS_RLL_SECRET \
    "http://127.0.0.1:$RS_RLL_PORT/rll/upgrade?exec=${rl_bin}-new"`
  if [[ $res =~ successful ]]; then
    # Delete the old version if it exists from the last upgrade.
    rm -fr ${rl_bin}-old
    # Keep the old version in case of issues, ie we need to manually revert back.
    mv ${rl_bin} ${rl_bin}-old
    cp ${rl_bin}-new ${rl_bin}
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
    source ${RLL_SECRET}
    new_installed_version=`curl --silent --show-error --request GET --header X-RLL-Secret:$RS_RLL_SECRET --globoff \
      "http://127.0.0.1:$RS_RLL_PORT/rll/proc/version" || true`
    if [[ $new_installed_version == $desired ]]; then
      logger -t rightlink "New version active - $new_installed_version"
      break
    else
      logger -t rightlink "Waiting for new version to become active."
      sleep 2
    fi
  done
  if [[ $new_installed_version != $desired ]]; then
    logger -t rightlink "New version does not appear to be desired version: $new_installed_version"
    exit 1
  fi

  # Report to audit entry that RightLink ugpraded.
  instance_json=`curl --silent --show-error --request GET --header X-RLL-Secret:$RS_RLL_SECRET --globoff \
    "http://127.0.0.1:$RS_RLL_PORT/api/sessions/instance"`
  re='\{"rel":"self","href":"(/api/clouds/[0-9]+/instances/[0-9a-zA-Z]*)"\}'
  if [[ $instance_json =~ $re ]]; then
    instance_href="${BASH_REMATCH[1]}"
    curl --silent --show-error --request POST --header X-RLL-Secret:$RS_RLL_SECRET --globoff \
      "http://127.0.0.1:$RS_RLL_PORT/api/audit_entries" \
      --data-urlencode "audit_entry[auditee_href]=${instance_href}" \
      --data-urlencode "audit_entry[detail]=RightLink updated to '${new_installed_version}'" \
      --data-urlencode 'audit_entry[summary]=RightLink updated'
  else
    logger -t rightlink "unable to obtain instance href for audit entries"
  fi
  exit 0
}

source ${RLL_SECRET}

# Detemine bin_path
rl_bin=`curl --silent --show-error --request GET --header X-RLL-Secret:$RS_RLL_SECRET --globoff \
  "http://127.0.0.1:$RS_RLL_PORT/rll/proc/bin_path"`
prefix_url='https://rightlinklite.rightscale.com/rll'

# Determine current version of rightlink
current_version=`curl --silent --show-error --request GET --header X-RLL-Secret:$RS_RLL_SECRET --globoff \
  "http://127.0.0.1:$RS_RLL_PORT/rll/proc/version"`

if [ -z $current_version ]; then
  echo "Can't determine current version of RLL"
  exit 1
fi

# Fetch information about what we should become. The "upgrades" file consists of lines formatted
# as "current_version:upgradeable_new_version". If the "upgrades" file does not exist,
# or if the current version is not in the file, no upgrade is done.
re="^\s*${current_version}\s*:\s*(\S+)\s*$"
match=`curl --silent --show-error --retry 3 ${prefix_url}/upgrades | egrep ${re} || true`
if [[ "$match" =~ $re ]]; then
  desired=${BASH_REMATCH[1]}
else
  echo "Cannot determine latest version from upgrade file"
  echo "Tried to match /^${current_version}:/ in ${prefix_url}/upgrades"
  exit 0
fi

if [[ $desired == $current_version ]]; then
  echo "RightLink is already up-to-date (current=$current_version)"
  exit 0
fi

echo "RightLink needs update:"
echo "  from current=$current_version"
echo "  to   desired=$desired"

echo "downloading RightLink version '$desired'"

# Download new version
cd /tmp
rm -rf rll rll.tgz
curl --silent --show-error --retry 3 --output rll.tgz $prefix_url/$desired/rightlinklite.tgz
tar zxf rll.tgz || (cat rll.tgz; exit 1)

# Check downloaded version
mv rll/rightlinklite ${rl_bin}-new
echo "checking new version"
new=`${rl_bin}-new -version | awk '{print $2}'`
if [[ $new == $desired ]]; then
  echo "new version looks right: $new"
  echo "restarting RightLink to pick up new version"
  # Fork a new task since this main process is started
  # by RightLink and we are restarting it.
  upgrade_rightlink &
else
  echo "Updated version does not appear to be desired version: ${new}"
  exit 1
fi
