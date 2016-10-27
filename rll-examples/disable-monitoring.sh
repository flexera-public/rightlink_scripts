#! /bin/bash -e

# ---
# RightScript Name: RightScale Linux Disable Monitoring
# Description: |
#   This downgrades an instance by disabling monitoring. It can be run against
#   any RightLink 5, 6, or 10 Server. It must be run after every reboot as the
#   scripts in the "Boot Scripts" will re-enable monitoring every boot and and
#   can't be disabled.
# Inputs: {}
# ...
#

# How this downgrade is accomplished differs by RightLink version. We try to be
# as minimally instrusive as possible, merely removing sending of any collectd
# stats to RightScale rather than disable collectd outright.
#
# The exact strategy to use differs by RightLink version/os.

sudo=
retry_flags=
is_rightlink10=0
# Ensure rsc is in the path
export PATH="/usr/local/bin:/opt/bin:$PATH"
which rsc >/dev/null && (rsc --help | grep retry >/dev/null) && retry_flags="--retry=5 --timeout=10"
# Ensure we sudo for RL10, which runs as the rightlink user. Don't sudo for RL6, which
# already runs as root and may fail due to sudoers configuration issues in some cases
which rightlink >/dev/null && is_rightlink10=1
[[ "$is_rightlink10" == "1" ]] && sudo="sudo"

# RL 10 supports built-in monitoring. Disable it if we detect it as on
if [[ "$is_rightlink10" == "1" ]]; then
  # Built-in monitoring didn't ship until 10.2.1, which also shipped with rsc.
  output=$(rsc rl10 show /rll/tss/control 2>/dev/null || true)
  if [[ "$output" =~ enable_monitoring ]] && [[ ! "$output" =~ "none" ]] && [[ ! "$output" =~ "false" ]]; then
    echo "RightLink 10 built-in monitoring is enabled. Disabling it."
    rsc rl10 $retry_flags update /rll/tss/control enable_monitoring=false
  else
    echo "RightLink 10 built-in monitoring is disabled."
  fi
fi

# RL 6 relied on collectd as a standalone service, which sends data directly to
# RightScale "sketchy" servers using the network plugin (UDP). Only the collectd
# v4 format is understood by UDP-based infrastructure. RL10 uses the native OS
# collectd, which can be collectd 4 or 5. In either case the data is sent over
# http to the RightLink client which adds an auth header and sends it onto the
# RightScale TSS servers. 
# Ubuntu location: /etc/collectd/plugins, RHEL/CentOS location: /etc/collectd.d
plugins_dir=/etc/collectd.d
if [[ -d /etc/collectd/plugins ]]; then
  plugins_dir=/etc/collectd/plugins
fi
collectd_conf=/etc/collectd.conf
if [[ -e /etc/collectd/collectd.conf ]]; then
  collectd_conf=/etc/collectd/collectd.conf
fi
if [[ -e $collectd_conf ]]; then
  echo "Collectd based monitoring detected."
  locations=($plugins_dir/network.conf $plugins_dir/write_http.conf)
  for filename in ${locations[*]}; do
    if $sudo test -f "$filename"; then
      if $sudo grep -E 'rightscale|rll/tss' "$filename" 2>/dev/null; then
        echo "RightScale collectd-based monitoring is enabled. Disabling collectd configuration $filename."
        backup_time=$(date -u +%Y%m%d%H%M%S)
        $sudo mv "${filename}" "${filename}.${backup_time}"
        restart_collectd=1
      fi
    fi
  done

  # Older (v13) style -- all-in-one config
  if $sudo grep -E 'Server.*rightscale.com' "$collectd_conf" 2>/dev/null; then
    echo "RightScale collectd-based monitoring is enabled. Disabling collectd configuration in $collectd_conf."
    backup_time=$(date -u +%Y%m%d%H%M%S)
    $sudo cp "${collectd_conf}" "${collectd_conf}.${backup_time}"
    $sudo perl -0777 -pi -e 's/LoadPlugin network.*?rightscale.*?Plugin>//is' "${collectd_conf}"
    restart_collectd=1
  fi

  # From https://collectd.org/wiki/index.php/Table_of_Plugins, all known "write"
  # plugins. If there are no write plugins enabled, collectd will spew errors
  # continually and is non-functional. Disable it in that case.
  write_plugins_regex="Plugin .*(amqp|carbon_writer|csv|network|rrdcached|rrdtool|unixsock|write_.*)"
  if $sudo grep -E "$write_plugins_regex" $(ls $plugins_dir/*.conf $collectd_conf); then
    echo "Found alternative collectd write plugin. Collectd will not be disabled."
  else
    echo "Found no collectd writer plugin other than the RightScale one."
    echo "Disabling collectd service as it does not appear to be setup for anything other than RightScale monitoring."
    disable_collectd=1
  fi

  if [[ "$disable_collectd" == "1" ]]; then
    if which chkconfig; then
      $sudo chkconfig collectd off
    elif which update-rc.d; then
      $sudo update-rc.d collectd disable
    fi
    echo "Collectd disabled. Stopping collectd service"
    if $sudo service collectd status; then
      $sudo service collectd stop
    fi
  elif [[ "$restart_collectd" == "1" ]]; then
    echo "Collectd configuration changed. Restarting collectd service."
    if $sudo service collectd status; then
      $sudo service collectd restart
    fi
  else
    echo "No changes to collectd configuration were needed."
  fi
fi

if [[ "$is_rightlink10" == "1" ]]; then
  rsc $retry_flags --rl10 cm15 multi_delete /api/tags/multi_delete \
    "resource_hrefs[]=$RS_SELF_HREF" \
    "tags[]=rs_monitoring:state=auth" \
    "tags[]=rs_monitoring:state=active" \
    "tags[]=rs_monitoring:util=v2"
else
  tags=$(rs_tag --list | grep rs_monitoring | sed 's/^[ ]*"//' | sed 's/".*//')
  for tag in $tags; do
    echo "Removing tag $tag"
    rs_tag --remove "$tag"
  done
fi
