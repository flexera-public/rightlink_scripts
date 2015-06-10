# This script either creates or updates a scheduled job that will run once a day that checks to
# see if there is an upgrade for RightLink

$scheduledJob = SCHTASKS.exe /Query /TN 'rightlink_check_upgrade' 2> $null
if ($env:ENABLE_AUTO_UPGRADE -eq 'false') {
  if ($scheduledJob) {
    SCHTASKS.exe /Delete /TN 'rightlink_check_upgrade' /F
    Write-Output 'Automatic upgrade disabled'
  } else {
    Write-Output 'Automatic upgrade never enabled - no action done'
  }
} else {
  # Random hour 0-23
  $jobHour = Get-Random -Min 0 -Max 24
  # Put a 0 on the front of the hour for the SCHTASKS time format
  if ($jobHour -lt 10) {
    $jobHour = "0" + $jobHour
  }

  # Random minute 0-59
  $jobMinute = Get-Random -Min 0 -Max 60
  # Put a 0 on the front of the minute for the SCHTASKS time format
  if ($jobMinute -lt 10) {
    $jobMinute = "0" + $jobMinute
  }

  if ($scheduledJob) {
    Write-Output 'Recreating schedule job'
    SCHTASKS.exe /Change /RU 'SYSTEM' /TN 'rightlink_check_upgrade' /ST ${jobHour}:${jobMinute}
  } else {
    SCHTASKS.exe /Create /RU 'SYSTEM' /ST ${jobHour}:${jobMinute} /SC DAILY `
    /TR "Powershell.exe & \\\`"C:\Program Files\RightScale\RightLink\rsc.exe\\\`" --rl10 cm15 schedule_recipe /api/right_net/scheduler/schedule_recipe recipe=rlw::upgrade" `
    /TN 'rightlink_check_upgrade'
  }

  # Check to make sure that the job was scheduled
  $newScheduledJob = SCHTASKS.exe /Query /TN 'rightlink_check_upgrade' 2> $null
  if ($newScheduledJob) {
    Write-Output 'Automatic upgrade enabled.'
  } else {
    Write-Output 'The scheduled job failed to be created!'
    Exit 1
  }
}


