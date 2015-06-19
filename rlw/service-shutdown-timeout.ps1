$ErrorActionPreference = 'Stop'

if ($env:SERVICE_SHUTDOWN_TIMEOUT) {
  $ServiceShutdownTimeoutSeconds = [int]$env:SERVICE_SHUTDOWN_TIMEOUT
} else {
  $ServiceShutdownTimeoutSeconds = 300
}
$ServiceShutdownTimeoutMilliseconds = $ServiceShutdownTimeoutSeconds * 1000

Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control WaitToKillServiceTimeout -Value $ServiceShutdownTimeoutMilliseconds
& "C:\Program Files\RightScale\RightLink\nssm.exe" set rightlink AppStopMethodConsole $ServiceShutdownTimeoutMilliseconds
