# ---
# RightScript Name: SYS IIS monitoring install
# Description: Installs IIS specific monitoring.
#
rsc rl10 create /rll/tss/exec/iis_monitor executable=[System.IO.Path]::GetFullPath(".\attachments\iis-monitor.ps1")
