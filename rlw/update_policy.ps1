$errorActionPreference = "Stop"

switch ($env:WINDOWS_AUTOMATIC_UPDATES_POLICY)
{
  "Disable automatic updates"     { $level = 1 }
  "Notify before download"        { $level = 2 }
  "Notify before installation"    { $level = 3 }
  "Install updates automatically" { $level = 4 }
}

try
{
  Write-Host "Getting Updates settings"
  $AUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
  Write-Host "Updates settings: $AUSettings"
  Write-Host "Setting Update Policy level: $level"
  $AUSettings.NotificationLevel = $level
  Write-Host "Saving policy"
  $AUSettings.Save()
  Write-Host "Policy saved"
}
catch
{
  throw "ERROR: $_"
  Exit 1
}
