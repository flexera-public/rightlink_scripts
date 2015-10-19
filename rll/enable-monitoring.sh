#! /bin/bash -e

# ---
# RightScript Name: RL10 Linux Enable Monitoring
# Description: Enable built-in RightLink system monitoring. This works with RightScale TSS (Time Series Storage),
#   a backend system for aggregating and displaying monitoring data.
# ...
#

# Determine location of rsc
[[ -e /usr/local/bin/rsc ]] && rsc=/usr/local/bin/rsc || rsc=/opt/bin/rsc

# Enable built-in monitoring
$rsc rl10 update /rll/tss/control enable_monitoring=all
