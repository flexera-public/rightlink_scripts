# ---
# RightScript Name: RL10 Windows Enable Monitoring
# Description: Enable built-in RightLink system monitoring. This works with RightScale TSS (Time Series Storage),
#   a backend system for aggregating and displaying monitoring data.
# Inputs: {}
# ...
#

# Enable built-in monitoring
rsc rl10 update /rll/tss/control enable_monitoring=all
