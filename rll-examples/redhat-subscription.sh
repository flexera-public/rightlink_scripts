#!/bin/bash

# ---
# RightScript Name: RL10 Linux RedHat Subscription Management
# Description: Used to register and unregister a RedHat instance with the RedHat subscription service
# Inputs:
#   REDHAT_ACCOUNT_USERNAME:
#     Input Type: single
#     Category: RightScale
#     Description: RedHat Account Username
#     Default: blank
#     Required: false
#     Advanced: true
#   REDHAT_ACCOUNT_PASSWORD:
#     Input Type: single
#     Category: RightScale
#     Description: RedHat Account Password
#     Default: blank
#     Required: false
#     Advanced: true
#   REDHAT_SUBSCRIPTION_ACTION:
#     Input Type: single
#     Category: RightScale
#     Description: Determine if this server should register or unregister from the RedHat Subscription
#     Required: false
#     Advanced: true
#     Default: text:register
#     Possible Values:
#       - text:register
#       - text:unregister
# Attachments: []
# ...

set -e

# Read/source os-release to obtain variable values determining OS
if [[ -e /etc/os-release ]]; then
  source /etc/os-release
else
  # CentOS/RHEL 6 does not use os-release, so use redhat-release
  if [[ -e /etc/redhat-release ]]; then
    # Assumed format example: CentOS release 6.7 (Final)
    ID=$(cut -d" " -f1 /etc/redhat-release)
    VERSION_ID=$(cut -d" " -f3 /etc/redhat-release)
  else
    echo "ERROR: /etc/os-release or /etc/redhat-release is required but does not exist"
    exit 1
  fi
fi

if [[ "$ID" != "redhat" ]]; then
  echo "RedHat Subscription Management is only used by RedHat Linux"
  exit 0
fi

# Check if server is already registered
if subscription-manager identity; then
  registered=true
else
  registered=false
fi

