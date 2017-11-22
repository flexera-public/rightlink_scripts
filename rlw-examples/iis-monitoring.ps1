# ---
# RightScript Name: SYS IIS monitoring install
# Description: Installs IIS specific monitoring.
# Inputs: {}
# Attachments:
#   - iis-monitor.ps1
# ...
#

$attachDir = $Env:RS_ATTACH_DIR
if (!$attachDir) {
  $attachDir = [System.IO.Path]::GetFullPath(".\attachments")
}

rsc rl10 create /rll/tss/exec/iis_monitor executable=$([io.path]::combine($attachDir, "iis-monitor.ps1"))
