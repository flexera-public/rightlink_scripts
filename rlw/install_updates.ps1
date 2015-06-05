$errorActionPreference = "Stop"

function ResolveError($errorRecord = $error[0])
{
  $errorRecord | Format-List * -Force | Out-String
  $errorRecord.InvocationInfo | Format-List * | Out-String
  $exception = $errorRecord.Exception
  for ($i = 0; $exception; $i++, ($exception = $exception.InnerException)) {
    "$i" * 80
    $exception | Format-List * -Force | Out-String
  }
}

try
{
  Write-Host "Starting script ..."
  $objSession = New-Object -ComObject "Microsoft.Update.Session" #Support local instance only
  $objSearcher = $objSession.CreateUpdateSearcher()
  $search = "IsInstalled = 0"
  Write-Host "Searching for new updates ..."
  try
  {
    $objResults = $objSearcher.Search($search)
  }
  catch
  {
    if ($_ -match "HRESULT: 0x80072EE2") {
      Write-Warning "Error searching for updates (HRESULT: 0x80072EE2) - connection to update server failed."
    }
    throw "An error occurred while search for updates to be installed."
  }
  if ($objResults.Updates.Count -eq 0) {
    Write-Host "No new updates found. Your system is up to date."
    Exit 0
  } else {
    Write-Host "Found $($objResults.Updates.Count) new updates. Now downloading updates ..."
  }
  # === Download Updates ===
  $DownloadedUpdateCollection = New-Object -ComObject "Microsoft.Update.UpdateColl"
  $FailedToDownloadUpdate = New-Object -ComObject "Microsoft.Update.UpdateColl"
  $EulaAcceptapceRequire = New-Object -ComObject "Microsoft.Update.UpdateColl"
  foreach ($update in $objResults.Updates) {
    $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
    $objCollectionTmp.Add($Update) | Out-Null
    $Downloader = $objSession.CreateUpdateDownloader()
    $Downloader.Updates = $objCollectionTmp
    try
    {
      Write-Debug "Try download update"
      $DownloadResult = $Downloader.Download()
    }
    catch
    {
      if ($_ -match "HRESULT: 0x80240044") {
        Write-Warning "HRESULT: 0x80240044 - permission denied. Please check your security policy."
      }
      throw "An error occurred while downloading an update."
    }
    Write-Debug "Check ResultCode"
    Switch -exact ($DownloadResult.ResultCode)
    {
      0 { $Status = "NotStarted" }
      1 { $Status = "InProgress" }
      2 { $Status = "Downloaded" }
      3 { $Status = "DownloadedWithErrors" }
      4 { $Status = "Failed" }
      5 { $Status = "Aborted" }
    }
    if (($DownloadResult.ResultCode -eq 2) -and ($($update.EulaAccepted) -eq $true)) {
      Write-Debug "Update KB$($update.KBArticleIDs) was successfully downloaded"
      $DownloadedUpdateCollection.Add($Update) | Out-Null
    }
    if (($DownloadResult.ResultCode -eq 2) -and ($($update.EulaAccepted) -eq $false)) {
      Write-Host "Update KB($($update.KBArticleIDs)) requires user accept EULA. This update will be only downloaded, but not installed. You can install it manually."
      $EulaAcceptapceRequire.Add($Update) | Out-Null
    }
    if ($DownloadResult.ResultCode -ne 2) {
      Write-Host "Downloading Update KB$($update.KBArticleIDs) failed with status $Status ."
      $FailedToDownloadUpdate.Add($Update)
    }
  }
  if ($EulaAcceptapceRequire.Count -ne 0) {
    Write-Host "The following updates were downloaded but not installed because they require to accept EULA before installation:"
    foreach ($Update in $EulaAcceptapceRequire) {
      Write-Host "($Update.KBArticleIDs)"
    }
  }
  if ($FailedToDownloadUpdate.Count -ne 0) {
    Write-Host "The following updates failed to download:"
    foreach ($update in $FailedToDownloadUpdate) {
      Write-Host "($Update.KBArticleIDs)"
    }
  }
  if ($DownloadedUpdateCollection.Count -eq 0) {
    throw "No updates were downloaded."
  } else {
    Write-Host "Updates to install:"
    foreach ($update in $DownloadedUpdateCollection) {
      Write-Host "KB$($update.KBArticleIDs)"
    }
  }

  # === Install Update ===
  Write-Host "Now installing downloaded updates ..."
  $NeedsReboot = $false
  $UpdateInstallationFailed = New-Object -ComObject "Microsoft.Update.UpdateColl"
  $UpdateInstallationReboot = New-Object -ComObject "Microsoft.Update.UpdateColl"
  foreach ($update in $DownloadedUpdateCollection) {
    $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
    $objCollectionTmp.Add($Update) | Out-Null
    $objInstaller = $objSession.CreateUpdateInstaller()
    $objInstaller.Updates = $objCollectionTmp
    try
    {
      Write-Debug "Trying to install update KB$($update.KBArticleIDs) ..."
      $InstallResult = $objInstaller.Install()
    }
    catch
    {
      if ($_ -match "HRESULT: 0x80240044") {
        Write-Warning "HRESULT: 0x80240044 - permission denied. Please check your security policy."
      }
      throw "Error installing update KB$($update.KBArticleIDs)."
    }
    if ($InstallResult.ResultCode -ne 2) {
      Switch -exact ($InstallResult.ResultCode)
      {
        0 { $Status = "NotStarted" }
        1 { $Status = "InProgress" }
        2 { $Status = "Installed" }
        3 { $Status = "InstalledWithErrors" }
        4 { $Status = "Failed" }
        5 { $Status = "Aborted" }
      }
      Write-Host "Update Installation Failed with $Status"
      $UpdateInstallationFailed.Add($update)
    }
    if ($InstallResult.ResultCode -eq 2) {
      Write-Host "Update KB$($update.KBArticleIDs) installation successfully completed"
      if ($($Update.RebootRequired) -eq $true) {
        Write-Host "KB$($update.KBArticleIDs) requires reboot to be applied."
        $UpdateInstallationReboot.Add($update)
      }
    }
    # if any update from collection require reboot, then mark sign NeedsReboot as true
    if (($NeedsReboot -eq $false) -and ($($Update.RebootRequired) -eq $true)) {
      $NeedsReboot = $Update.RebootRequired
    }
  }
  if ($UpdateInstallationFailed.Count -ne 0) {
    Write-Host "Installation of the following updates failed:"
    foreach ($Update in $UpdateInstallationFailed) {
      Write-Host "($Update.KBArticleIDs)"
    }
  }
  if ($UpdateInstallationReboot -ne 0) {
    Write-Host "Updates that require reboot to take effect:"
    foreach ($update in $UpdateInstallationReboot) {
      Write-Host "KB$($update.KBArticleIDs)"
    }
  }
  # checks if any update requires reboot after installation
  if ($NeedsReboot) {
    $Reboot_Behavior = $env:WINDOWS_UPDATES_REBOOT_SETTING
    if ($Reboot_Behavior -eq "Allow Reboot") {
      Restart-Computer -Force
    } else {
      return "Reboot is required, but not allowed by WINDOWS_UPDATES_REBOOT_SETTING input. Please do the reboot manually."
    }
  }
}
catch
{
  ResolveError
  Exit 1
}
