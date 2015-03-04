#!/bin/bash

# Will compare current version of rightlink 'running' with latest version provided from 'upgrades'
# file. If they differ, will update to latest version.  Note that latest version can be an older version
# if a downgrade is best.

# -e will immediatly exit out of script at point of error
# -x print each command to stdout before exxecuting it
set -ex

source /var/run/rll-secret

# Detemine bin_path
rl_bin=`curl -sS -X GET -H X-RLL-Secret:$RS_RLL_SECRET -g "http://127.0.0.1:$RS_RLL_PORT/rll/proc/bin_path"`
prefix_url='https://rightlinklite.rightscale.com/rll'

# Determine current version of rightlink
current_version=`curl -sS -X GET -H X-RLL-Secret:$RS_RLL_SECRET -g "http://127.0.0.1:$RS_RLL_PORT/rll/proc/version"`

if [ -z $current_version]; then
  echo "Can't determine current version of RLL"
  exit 1
fi

# Fetch information about what we should become. The "upgrades" file is obtained
# using the name of the current version.  The file consists of lines formatted as
# "current_version: upgradeable_new_version"
# If the "upgrades" file does not exist, no upgrade is done.
match=`curl -sS --retry 3 $prefix_url/${current_version}/upgrades | egrep "^${current_version}:" || true`
re="^${current_version}: *([^ ]*)"
if [[ "$match" =~ $re ]]; then
  desired=${BASH_REMATCH[1]}
else
  echo "Cannot determine latest version from upgrade file"
  echo "Tried to match /^${current_version}:/ in $prefix_url/${current_version}/upgrades"
  exit 0
fi

if [[ $desired == $current ]]; then
  echo "RightLink already up-to-date (current=$current)"
  exit 0
fi

echo "RightLink needs update:"
echo "  from current=$current"
echo "  to   desired=$desired"
 
echo "downloading RightLink version '$desired'"

# Download new version
cd /tmp
rm -rf rll rll.tgz
curl -sS --retry 3 -o rll.tgz $prefix_url/$desired/rightlinklite.tgz
tar zxf rll.tgz || (cat rll.tgz; exit 1)

# Check downloaded version
mv rll/rightlinklite ${rl_bin}-new
echo "checking new version"
new=`${rl_bin}-new -version`
if [[ $new == $desired ]]; then
  echo "new version looks right: $new"
  echo "restarting RightLink to pick up new version"
  res=`curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET "http://127.0.0.1:$RS_RLL_PORT/rll/upgrade?exec=${rl_bin}-new"`
  if [[ $res =~ successful ]]; then
    # Delete the old version if it exists from the last upgrade.
    rm -fr ${rl_bin}-old
    # Keep the old version in case of issues, ie we need to manually revert back.
    mv ${rl_bin} ${rl_bin}-old
    cp ${rl_bin}-new ${rl_bin}
    echo DONE
  else
    echo "Error: $res"
    exit 1
  fi
else
  echo "Updated version does not appear to be desired version: ${new}"
  exit 1
fi

# Check version in production by connecting to local proxy
# The update takes a few seconds so retries are done.
for retry_counter in {1..5};
do
  new_installed_version=`curl -sS -X GET -H X-RLL-Secret:$RS_RLL_SECRET -g "http://127.0.0.1:$RS_RLL_PORT/rll/proc/version"`
  if [[ $new_via_proxy == $desired ]]; then
    echo "New version in production - $new_installed_version"
    break
  else
    echo "Waiting for new version to become active."
    sleep 2
  fi
done
if [[ $new_installed_version != $desired ]]; then
  echo "New version does not appear to be desired version: $new_installed_version"
  exit 1
fi
