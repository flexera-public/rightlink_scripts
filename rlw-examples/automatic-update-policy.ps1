# ---
# RightScript Name: RL10 Windows Automatic Update Policy
# Description: Sets the policy for automatic updates.
# Inputs:
#   WINDOWS_AUTOMATIC_UPDATES_POLICY:
#     Input Type: single
#     Category: RightScale
#     Description: The automatic updates policy setting.
#     Default: text:Disable automatic updates
#     Required: false
#     Advanced: true
#     Possible Values:
#       - text:Disable automatic updates
#       - text:Notify before download
#       - text:Notify before installation
#       - text:Install updates automatically
# ...
#

$errorActionPreference = 'Stop'

switch ($env:WINDOWS_AUTOMATIC_UPDATES_POLICY)
{
  'Disable automatic updates'     { $level = 1 }
  'Notify before download'        { $level = 2 }
  'Notify before installation'    { $level = 3 }
  'Install updates automatically' { $level = 4 }
}

Write-Host 'Getting Updates settings'
$AUSettings = (New-Object -com 'Microsoft.Update.AutoUpdate').Settings
Write-Host "Updates settings: ${AUSettings}"
Write-Host "Setting Update Policy level: ${level}"
$AUSettings.NotificationLevel = $level
Write-Host 'Saving policy'
$AUSettings.Save()
Write-Host 'Policy saved'
