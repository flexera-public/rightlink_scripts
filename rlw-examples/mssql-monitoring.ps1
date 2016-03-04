# ---
# RightScript Name: DB SQLS Install monitors
# Description: Installs Microsoft SQL Server specific monitoring. 
# Inputs: {}
# Attachments:
#   - iis-monitor.ps1
# ...
#

$attachDir = $Env:RS_ATTACH_DIR
if (!$attachDir) {
  $attachDir = [System.IO.Path]::GetFullPath(".\attachments")
}

rsc rl10 create /rll/tss/exec/mssql_monitor executable=[io.path]::combine($attachDir, "mssql-monitor.ps1")
