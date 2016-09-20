#!/bin/bash

# ---
# RightScript Name: RL10 Linux RedHat Subscription Register
# Description: Register a RedHat instance with the RedHat subscription service and enable additional repos
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
#   REDHAT_ADDITIONAL_REPOS:
#     Input Type: single
#     Category: RightScale
#     Description: Space separated list of additional RHEL repos to enable.
#     Default: blank
#     Required: false
#     Advanced: true
# Attachments: []
# ...

set -e

# Read/source os-release to obtain variable values determining OS
if [[ -e /etc/os-release ]]; then
  source /etc/os-release
# CentOS/RHEL 6 does not use os-release, so use redhat-release
elif [[ -e /etc/redhat-release ]]; then
  # Assumed format example: CentOS release 6.7 (Final)
  ID=$(cut -d" " -f1 /etc/redhat-release)
  VERSION_ID=$(cut -d" " -f3 /etc/redhat-release)
else
  echo "Unable to determine OS as /etc/os-release or /etc/redhat-release does not exist"
fi
if [[ "$ID" != "rhel" ]]; then
  echo "RedHat Subscription Management is only used by RedHat Linux"
  exit 0
fi

# If REDHAT_ACCOUNT_USERNAME or REDHAT_ACCOUNT_PASSWORD is not set, exit
if ([[ -z "$REDHAT_ACCOUNT_USERNAME" ]] || [[ -z "$REDHAT_ACCOUNT_PASSWORD" ]]); then
  echo "Username and/or password is not set - continuing without registration"
  exit 0
fi

# Install subscription-manager
sudo yum --assumeyes install subscription-manager

# Check if server is already registered
if sudo subscription-manager identity; then
  echo "System is already registered"
else
  echo "Registering system"
  sudo subscription-manager register --username $REDHAT_ACCOUNT_USERNAME --password $REDHAT_ACCOUNT_PASSWORD --auto-attach
fi

# Enable additional repos if provided
for repo in $REDHAT_ADDITIONAL_REPOS; do
  echo "enabling additional repo - $repo"
  sudo subscription-manager repos --enable=$repo
done
