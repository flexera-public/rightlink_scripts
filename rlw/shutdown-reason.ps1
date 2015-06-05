Write-Output "===== DECOMMISSIONING ====="

$systemStateEntry = Get-Eventlog -LogName system -Source User32 | ? { $_.eventid -eq 1074 } | Select -First 1

switch -regex ($systemstateentry.message)
{
  ".*restart.*" { $reason = "rebooting" }
  ".*(power off|shutdown).*" { $reason = "shutting down" }
  default { $reason = "unknown" }
}

Write-Output "The system is going down -> $reason"
