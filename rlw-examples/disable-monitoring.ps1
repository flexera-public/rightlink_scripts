# ---
# RightScript Name: RightScale Windows Disable Monitoring
# Description: |
#   This downgrades an instance by disabling monitoring. It can be run against
#   any RightLink 5, 6, or 10 Server. It must be run after every reboot as the
#   scripts in the "Boot Scripts" will re-enable monitoring every boot and and
#   can't be disabled.
# Inputs: {}
# ...
#

# How this downgrade is accomplished differs by RightLink version. See below.

$rl6ServiceDir = "${env:ProgramFiles(x86)}\RightScale\RightLinkService"
$scriptsDir = "$rl6ServiceDir\scripts"

if (Test-Path "C:\Program Files\RightScale\RightLink\rightlink.exe") {
  # RightLink 10 style monitoring. We simply make a disablement call.
  $rsc="C:\Program Files\RightScale\RightLink\rsc.exe"
  $output=& $rsc rl10 show /rll/tss/control
  if (($output -Match "enable_monitoring") -and ($output -NotMatch "false|none")) {
    & $rsc rl10 $retry_flags update /rll/tss/control enable_monitoring=false
    Write-Output "RightLink 10 built-in monitoring is enabled. Disabling it."
  } else {
    Write-Output "RightLink 10 built-in monitoring is disabled."
  }
  & $rsc --rl10 cm15 multi_delete /api/tags/multi_delete "resource_hrefs[]=$env:RS_SELF_HREF" "tags[]=rs_monitoring:state=auth" "tags[]=rs_monitoring:state=active" "tags[]=rs_monitoring:util=v2"
} elseif (Test-Path $rl6ServiceDir) {
  # RightLink 5/6 style monitoring. There's a side-car ruby service which gathers
  # monitoring data which we proceed to disable.
  Write-Output "Checking for RightLink 5/6 based monitoring"
  if (!(Test-Path "$scriptsDir")) {
    Write-Output "Cannot find $scriptsDir, monitoring is disabled."
    exit 0
  }
  $files = @(Get-ChildItem $scriptsDir)
  if ($files.Length -gt 0) {
    Write-Output "RightLink based 5/6 monitoring enabled, disabling"
    foreach ($file in $files) {
      Remove-Item $file.FullName -Force -Recurse
    }
  } else {
    Write-Output "RightScale monitoring is disabled."
  }
  $rubyProcs = Get-WmiObject win32_process -Filter "name='ruby.exe'"
  ForEach($proc in $rubyProcs) {
    if ($proc.CommandLine -Match "monitoring") {
      Write-Output "Killing monitoring process PID $($proc.ProcessId)"
      taskkill.exe /PID $proc.ProcessId /F
    }
  }
  $tags = rs_tag --list
  if ($tags -Match "rs_monitoring") {
    Write-Output "Removing rs_monitoring:state=active tag"
    rs_tag --remove "rs_monitoring:state=active"
  }
} else {
  Write-Output "Neither a RightLink 5, 6, or 10 installation was detected, don't know what to do!"
  exit 1
}

