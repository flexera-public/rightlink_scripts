#!/bin/bash
# ---
# RightScript Name: RL10 Linux Setup Alerts
# Description: |
#   Set up the RightScale Alerts on the instance to match the metrics that it is actually reporting with either built-in
#   RightLink monitoring or collectd. The RightScale Alerts on this ServerTemplate are set to match the metrics reported
#   by the built-in RightLink monitoring and collectd 5, but there are a few metrics which have names which vary based
#   on the system they are running and there are also some metrics which have different names with collectd 4 which is
#   used on older Linux distribution versions (such as Ubuntu 12.04 and CentOS 6).
#
#   The alerts that need to be set up by this script are:
#
#   * *rs low space in root partition*: If a Linux system is running collectd 4, the metric used for this alert will be
#     set to `df/df-root.free` rather than `df-root/df_complex-free.value`.
#   * *rs high network tx activity* and *rs high network rx activity*: On newer Linux distribution versions (such as
#     CoreOS and Ubuntu 16.04) the network interface name is not necessarily `eth0` and there may be more network
#     interfaces on the system, so this script will update and add the alerts to match the network interfaces on the
#     system.
#   * *rs low swap space*: If no swap is set up on a Linux system, no swap metrics will be sent. If you enable swap on
#     the system at a later point, this script can be rerun to re-enable the alert.
# Inputs:
#   MONITORING_METHOD:
#     Input Type: single
#     Category: RightScale
#     Description: |
#       Determine the method of monitoring to use, either RightLink monitoring or collectd. Setting to
#       'auto' will use code to select method.
#     Required: true
#     Advanced: true
#     Default: text:auto
#     Possible Values:
#       - text:auto
#       - text:collectd
#       - text:rightlink
# Attachments: []
# ...

set -e

function create_alert_spec() {
  local template_name="$1"
  local name="$template_name $2"
  shift 2

  echo -n "creating alert spec '$name' from '${template_name}': overriding $@ ... "
  if rsc json --x1 "object:has(.name:val(\"$name\"))" <<<"$alert_specs" 1>/dev/null 2>&1; then
    echo 'already exists'
    return
  fi

  local -A parameters=([name]="$name")
  for parameter in condition description duration escalation_name file threshold variable vote_tag vote_type; do
    value=`rsc json --x1 "object:has(.name:val(\"$template_name\")).$parameter" <<<"$alert_specs" 2>/dev/null || true`
    if [[ -n "$value" ]]; then
      parameters[$parameter]="$value"
    fi
  done

  while [[ $# -gt 0 ]]; do
    local parameter="$1"
    local value="$2"
    parameters[$parameter]="$value"
    shift 2
  done

  local -a arguments
  for parameter in "${!parameters[@]}"; do
    arguments[${#arguments[@]}]="alert_spec[$parameter]=${parameters[$parameter]}"
  done

  rsc --rl10 cm15 create "$RS_SELF_HREF/alert_specs" "${arguments[@]}"
  echo 'created'
}

function destroy_alert_or_alert_spec() {
  local name="$1"

  echo -n "destroying alert or alert spec '$name' from instance: ... "
  if ! alert_for_alert_spec_exists "$name"; then
    echo 'already destroy'
    return
  fi

  if [[ $subject_href =~ ^/api/server_templates/[^/]+$ ]]; then
    alert_href=`rsc json --xj "object:has(.href:val(\"$alert_spec_href\")) ~ object" <<<"$alerts" | rsc json --x1 'object:has(.rel:val("self")).href'`
    rsc --rl10 cm15 destroy "$alert_href"
  else
    rsc --rl10 cm15 destroy "$alert_spec_href"
  fi

  echo 'destroyed'
}

function alert_for_alert_spec_exists() {
  local name="$1"
  alert_spec_href=`rsc json --x1 "object:has(.name:val(\"$name\")) object:has(.rel:val(\"self\")).href" <<<"$alert_specs" 2>/dev/null`
  subject_href=`rsc json --x1 "object:has(.name:val(\"$name\")) object:has(.rel:val(\"subject\")).href" <<<"$alert_specs" 2>/dev/null`

  if [[ -n $alert_spec_href ]]; then
    if [[ $subject_href =~ ^/api/server_templates/[^/]+$ ]]; then
      if rsc json --x1 "object:has(.href:val(\"$alert_spec_href\"))" <<<"$alerts" 1>/dev/null 2>&1; then
        return 0
      else
        return 1
      fi
    else
      return 0
    fi
  else
    return 1
  fi
}

# Ensure rsc is in the path
export PATH="/usr/local/bin:/opt/bin:$PATH"

# Determine what mode to use if MONITORING_METHOD is set to 'auto'
if [[ "$MONITORING_METHOD" == "auto" ]]; then
  # Currently, the only criteria to automatically use RightLink monitoring is if OS is CoreOS
  if grep -iq "id=coreos" /etc/os-release 2> /dev/null; then
    monitoring_method="rightlink"
  else
    monitoring_method="collectd"
  fi
else
  monitoring_method=$MONITORING_METHOD
fi

# Determine which network interfaces exist excluding lo so we can update alert specs and configure collectd
interfaces=(`ip -o link | awk '{ sub(/:$/, "", $2); if ($2 != "lo") { print $2; } }'`)

# Determine if swap is enabled
if [[ $(sudo swapon -s | wc -l) -gt 1 ]]; then
  swap=1
else
  swap=0
fi

alert_specs=`rsc --rl10 cm15 index "$RS_SELF_HREF/alert_specs" with_inherited=true`
alerts=`rsc --rl10 cm15 index "$RS_SELF_HREF/alerts"`

if [[ $swap -eq 0 ]]; then
  destroy_alert_or_alert_spec 'rs low swap space'
  destroy_alert_or_alert_spec 'rs low swap space recreated'
else
  if ! alert_for_alert_spec_exists 'rs low swap space' && ! alert_for_alert_spec_exists 'rs low swap space recreated'; then
    create_alert_spec 'rs low swap space' recreated
  fi
fi

disable_eth0=1
reenable_eth0=0
interface_file='interface-eth0/if_octets'

if [[ $monitoring == collectd && "$(collectd -h)" =~ "collectd 4" ]]; then
  destroy_alert_or_alert_spec 'rs low space in root partition'
  create_alert_spec 'rs low space in root partition' 'collectd4' file df/df-root variable free

  reenable_eth0=1
  interface_file='interface/if_octets-eth0'
fi

for interface in "${interfaces[@]}"; do
  if [[ "$interface" == eth0 && $reenable_eth0 -eq 0 ]]; then
    disable_eth0=0
    continue
  fi

  create_alert_spec 'rs high network tx activity' "$interface" file "${interface_file/eth0/$interface}"
  create_alert_spec 'rs high network rx activity' "$interface" file "${interface_file/eth0/$interface}"
done

if [[ disable_eth0 -eq 1 ]]; then
  destroy_alert_or_alert_spec 'rs high network tx activity'
  destroy_alert_or_alert_spec 'rs high network rx activity'
fi
