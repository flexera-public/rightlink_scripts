# ---
# RightScript Name: RL10 Windows Enable Monitoring
# Description: Enable built-in RightLink system monitoring. This works with RightScale TSS (Time Series Storage),
#   a backend system for aggregating and displaying monitoring data.
# ...
#

# Enable built-in monitoring
rsc rl10 put_control /rll/tss/control enable_monitoring=true
