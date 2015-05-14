#! /bin/bash

# The server's hostname is set to the longest valid prefix or suffix of
# this SERVER_HOSTNAME variable eg 'my.example.com V2', 'NEW my.example.com', and
# 'database.io my.example.com' all set the hostname to 'my.example.com'.
# If SERVER_HOSTNAME is empty, will maintain current hostname.

set -ex

if [[ -n "$SERVER_HOSTNAME" ]]; then
  prefix=
  suffix=

  re='^[-A-Za-z0-9_][-A-Za-z0-9_.]*[-A-Za-z0-9_]'
  if [[ "$SERVER_HOSTNAME" =~ $re ]]; then
    prefix=${BASH_REMATCH[0]}
    echo "prefix set to ${prefix}"
  fi
  re='[-A-Za-z0-9_][-A-Za-z0-9._]*[-A-Za-z0-9_]$'
  if [[ "$SERVER_HOSTNAME" =~ $re ]]; then
    suffix=${BASH_REMATCH[0]}
    echo "suffix set to ${suffix}"
  fi

  if (( ${#prefix} >= ${#suffix} && ${#prefix} > 1 )); then
    echo "Setting hostname to prefix '$prefix'"
    sudo hostname "$prefix"
  elif (( ${#suffix} > 1 )); then
    echo "Setting hostname to suffix '$suffix'"
    sudo hostname "$suffix"
  fi
fi
