# ---
# RightScript Name: RL10 Windows Enable Monitoring
# Description: Enable built-in RightLink system monitoring. This works with RightScale TSS (Time Series Storage),
#   a backend system for aggregating and displaying monitoring data.
# ...
#

# Enable built-in monitoring
rsc rl10 put_control /rll/tss/control enable_monitoring=true

# Add the RightScale monitoring active tag
rsc --rl10 cm15 multi_add /api/tags/multi_add resource_hrefs[]=$env:RS_SELF_HREF tags[]=rs_monitoring:state=auth
