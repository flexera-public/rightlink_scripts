$errorActionPreference = "Stop"

$scheduledJob = Get-ScheduledJob -Name "rightlink_check_upgrade" 2> $null
if ($env:ENABLE_AUTO_UPGRADE -eq "false") {
  if ($scheduledJob) {
    Unregister-ScheduledJob -Name "rightlink_check_upgrade"
    Write-Output "Automatic upgrade disabled"
  } else {
    Write-Output "Automatic upgrade never enabled - no action done"
  }
} else {
  # Random hour 0-23
  $job_hour = Get-Random -Min 0 -Max 24

  # Random minute 0-59
  $job_minute = Get-Random -Min 0 -Max 60

  $trigger = New-JobTrigger -Daily -At ${job_hour}:${job_minute}

  if ($scheduledJob) {
    Write-Output "Recreating schedule job"
    Set-ScheduledJob -InputObject $scheduledJob -Trigger $trigger
  } else {
    Register-ScheduledJob -Name "rightlink_check_upgrade" -Trigger $trigger -ScriptBlock {
      & rsc --rl10 cm15 schedule_recipe /api/right_net/scheduler/schedule_recipe recipe=rll::upgrade
    }
  }

  Write-Output "Automatic upgrade enabled."
}
