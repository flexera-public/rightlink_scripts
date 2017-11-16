# ---
# RightScript Name: RL10 Windows Enable Monitoring
# Description: Enable built-in RightLink system monitoring. This works with RightScale TSS (Time Series Storage),
#   a backend system for aggregating and displaying monitoring data.
# Inputs: {}
# ...
#

# Enable built-in monitoring
$RIGHTLINK_DIR = "$env:ProgramFiles\RightScale\RightLink"
& ${RIGHTLINK_DIR}\rsc.exe --retry=5 --timeout=10 rl10 update /rll/tss/control enable_monitoring=all
