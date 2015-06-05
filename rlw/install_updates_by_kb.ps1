$errorActionPreference = "Stop"

function ResolveError($errorRecord = $error[0])
{
  $errorRecord | Format-List * -Force | Out-String
  $errorRecord.InvocationInfo | Format-List * | Out-String
  $exception = $errorRecord.Exception
  for ($i = 0; $exception; $i++, ($exception = $exception.InnerException))
  {
    "$i" * 80
    $exception | Format-List * -Force | Out-String
  }
}

$KBArticle = $env:KB_ARTICLE_NUMBER
$Reboot_Option = $env:WINDOWS_UPDATES_REBOOT_SETTING

try
{
  Write-Host "Stage 1: Searching for requested update"
  # This flag is used when update requires EULA acceptance. If EULA acceptance required then update will be only downloaded, but not installed.
  $installflag = $true
  $DebugPreference = 'Continue'
  Write-Debug "Input parameters $($KBArticle.Length), $($Reboot_if_required.Length)"

  # Check if parameters are not null
  if ($KBArticle.Length -eq 0 ) {
    Write-Host "Update KB number is not set. Please run the script providing correct KB update number (Ex.: KB123456, or 123456)"
    Exit 1
  }
  Write-Debug "Checking input"
  if ($KBArticle -match '[KkBb](\d+)') {
    Write-Debug "Result check is matching pattern $match"
    $KBArticle = $matches[1]
  }

  $UpdatesToDownload = New-Object -ComObject "Microsoft.Update.UpdateColl"
  $objSession = New-Object -ComObject "Microsoft.Update.Session" # Support local instance only
  $objSearcher = $objSession.CreateUpdateSearcher()

  # Checks if update was installed earlier
  Write-Host "Checking if update KB$($KBArticle) was installed"
  $search = "IsInstalled = 1"
  $objResults = $objSearcher.Search($search)
  foreach ($Update in $objResults.Updates) {
    if ($Update.KBArticleIDs -eq $KBArticle) {
      $InstalledUpdate = New-Object -ComObject "Microsoft.Update.UpdateColl"
      $InstalledUpdate.Add($update) | Out-Null
      Write-Host "Found installed version of update KB$($KBArticle)"
      $exist = $true
    }
  }
  if ($exist -eq $false) {
    Write-Host "KB$($KBArticle) was not installed earlier"
  }
  Write-Host "Searching in new updates ..."
  $search = "IsInstalled = 0"
  $objResults = $objSearcher.Search($search)
  foreach ($Update in $objResults.Updates) {
    if ($Update.KBArticleIDs -eq $KBArticle) {
      Write-Host "Update KB$($KBArticle) found"
      $UpdatesToDownload.Add($Update) | Out-Null
    }
  }
  $AcceptUpdatesToDownload = $UpdatesToDownload.Count

  if ($exist -and $AcceptUpdatesToDownload -gt 0) {
    Write-Debug "Checking dates of installed update and update to download ..."
    foreach ($item_old in $InstalledUpdate) {
      $InstalledUpdateDate = [DateTime]$item_old.LastDeploymentChangeTime
    }
    foreach ($item_new in $UpdatesToDownload) {
      $DownloadedUpdateTime = [DateTime]$item_new.LastDeploymentChangeTime
    }
    if ($DownloadedUpdateTime -le $InstalledUpdateDate) {
      Write-Host "Version of installed update KB$($Update.KBArticleIDs) is newer than you are trying to install"
      Exit 1
    }
    if ($DownloadedUpdateTime -gt $InstalledUpdateDate) {
      Write-Host "Version of downloaded update is newer then installed."
    }
  }
  if ($exist -and $AcceptUpdatesToDownload -lt 1) {
    Write-Host "Update KB$($KBArticle) is already installed."
    Exit 0
  }
  if (!$exist -and $AcceptUpdatesToDownload -lt 1) {
    Write-Host "Update KB$($KBArticle) was not installed and was not found in new updates. Please make sure the update is applicable to this server configuration."
    Exit 0
  }
  Write-Host "Check if EULA acceptance required"
  foreach ($update in $UpdatesToDownload) {
    Write-Host "EULA Acceptance property setting is: $($update.EulaAccepted)"
    if ($update.EulaAccepted -eq $false) {
      $installflag = $false
      Write-Host "This update will be only downloaded, but not installed since it requires user to read and accept the license agreement."
    } else {
      Write-Host "This update will be downloaded and installed. Starting stage 2: downloading update"
    }
  }

  Write-Host "STAGE 2: Download update"
  $objCollectionDownload = New-Object -ComObject "Microsoft.Update.UpdateColl"
  foreach ($Update in $UpdatesToDownload) {
    Write-Host "Show update to download: $($Update.Title)"
    Write-Host "Send update to download collection"
    $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
    $objCollectionTmp.Add($Update) | Out-Null
    Write-Host "Dowloading Update $($Update.Title)"
    $Downloader = $objSession.CreateUpdateDownloader()
    $Downloader.Updates = $objCollectionTmp
    Write-Host "Starting downloading. Will try for three times in case of any issues"
    for ($i = 0; $i -le 3; $i++) {
      try
      {
        Write-Host "Trying to download update KB$($Update.KBArticleIDs). Attempt $i of 3"
        $DownloadResult = $Downloader.Download()
      }
      catch
      {
        Write-Host "Failed to download update KB$($Update.KBArticleIDs) $_ "
        if ($_ -match "HRESULT: 0x80240044" -and $i -eq 2) {
          Write-Host "Your security policy don't allow a non-administator identity to perform this task"
        }
      Return
      }
      if ($DownloadResult.ResultCode -eq 2) {
        break
      }
    }
    if ($DownloadResult.ResultCode -eq 2) {
      Write-Host "Downloaded then send update to the next stage 3: Install update"
      $objCollectionDownload.Add($Update) | Out-Null
    } else {
      Write-Host "Error while downloading update KB$($Update.KBArticleIDs)"
      Exit 1
    }
  }

  $ReadyUpdatesToInstall = $objCollectionDownload.Count
  Write-Debug "Downloaded [$ReadyUpdatesToInstall] Updates to Install"
  if ($ReadyUpdatesToInstall -eq 0) {
    Return
  }

  Write-Host "STAGE 3: Install updates"
  if (!$installflag) {
    Write-Host "KB$($Update.KBArticleIDs) has been downloaded but not installed. This KB requires user to read and accept license agreement";
    Exit 1
  }
  $NeedsReboot = $false
  # Install updates
  foreach ($Update in $objCollectionDownload) {
    Write-Debug "Show update to install: $($Update.Title)"
    Write-Host "Send update to install collection"
    $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
    $objCollectionTmp.Add($Update) | Out-Null
    $objInstaller = $objSession.CreateUpdateInstaller()
    $objInstaller.Updates = $objCollectionTmp
    Write-Host "Trying to install update"
    try
    {
      Write-Host "Try install update"
      $InstallResult = $objInstaller.Install()
    }
    catch
    {
      if ($_ -match "HRESULT: 0x80240044") {
        Write-Host "Your security policy don't allow a non-administator identity to perform this task"
      }
      Return
    }
    if (!$NeedsReboot) {
      Write-Debug "Set instalation status RebootRequired"
      $NeedsReboot = $installResult.RebootRequired
    }
    Switch -exact ($InstallResult.ResultCode)
    {
      0 { $Status = "NotStarted" }
      1 { $Status = "InProgress" }
      2 { $Status = "Installed" }
      3 { $Status = "InstalledWithErrors" }
      4 { $Status = "Failed" }
      5 { $Status = "Aborted" }
    }
  }
  if($NeedsReboot) {
    if ($Reboot_Option -eq "Allow Reboot") {
      Write-Host ("Update was installed and require reboot.")
      Restart-Computer -Force
    }
    if ($Reboot_Option -eq "Do Not Allow Reboot") {
      Write-Host "KB$($Update.KBArticleIDs) has been installed but requires a reboot to be applied to the system "
    }
  }
}
catch
{
  ResolveError
  Exit 1
}
