# ---
# RightScript Name: RL10 Windows Upgrade
# Description: Check whether a RightLink upgrade is available and perform the upgrade.
# Inputs:
#   UPGRADES_FILE_LOCATION:
#     Input Type: single
#     Category: RightScale
#     Description: External location of 'upgrades' file
#     Default: text:https://rightlink.rightscale.com/rightlink/upgrades
#     Required: false
#     Advanced: true
# ...
#

# Will compare current version of rightlink 'running' with latest version provided from 'upgrades'
# file. If they differ, will update to latest version.  Note that latest version can be an older version
# if a downgrade is best.

function Expand-Zipfile($zipFile, $targetDir, $basePath = $Null)
{
  if (! $basePath) { $basePath = $zipFile }
  $shell = New-Object -com Shell.Application
  $zip = $shell.NameSpace($zipFile)

  if (!(Test-Path -Path $targetDir)) {
    New-Item -Path $targetDir -Type directory
  }
  foreach ($item in $zip.items()) {
    $newPath = $item.path -replace [RegEx]::Escape($basePath), $targetDir
    if ($item.Type -eq "File Folder") {
      New-Item -Path $newPath -Type directory
      Expand-Zipfile $item.Path $targetDir $basePath
    } else {
      $newDir = [io.path]::GetDirectoryName($newPath)
      $shell.Namespace($newDir).CopyHere($item)
    }
  }
}

$upgradeFunction = {
  function upgradeRightLink($currentVersion, $desiredVersion) {
    $RIGHTLINK_DIR = 'C:\Program Files\RightScale\RightLink'

    # Self upgrade API call is not yet supported on Windows, but we can still use the API call to verify the exe
    $upgradeCheck = & ${RIGHTLINK_DIR}\rsc.exe rl10 upgrade /rll/upgrade exec=${RIGHTLINK_DIR}\rightlink-new.exe 2> $null
    if ($upgradeCheck -match 'successful') {
      # Delete the old version if it exists from the last upgrade.
      if (Test-Path -Path ${RIGHTLINK_DIR}\rightlink-old.exe) {
        Remove-Item -Path ${RIGHTLINK_DIR}\rightlink-old.exe -Force
      }
      # Keep the old version in case of issues, ie we need to manually revert back.
      Rename-Item -Path ${RIGHTLINK_DIR}\rightlink.exe -newName 'rightlink-old.exe' -Force
      Rename-Item -Path ${RIGHTLINK_DIR}\rightlink-new.exe -newName 'rightlink.exe' -Force
      # We kill the current running rightlink process,
      # Since we renamed the new version to rightlink.exe, it should be started automatically by NSSM
      Stop-Process -Name 'rightlink' -Force
    } else {
      Write-Output """Error: ${upgradeCheck}"""
      Exit 1
    }
    # Check updated version in production by connecting to local proxy
    # The update takes a few seconds so retries are done.
    for ($i = 1; $i -le 5; $i += 1) {
      $newInstalledVersion = & ${RIGHTLINK_DIR}\rsc.exe --x1 .version rl10 index proc 2> $null
      if ($newInstalledVersion -eq $desiredVersion) {
        Write-Output """New version active - ${newInstalledVersion}"""
        break
      } else {
        Write-Output 'Waiting for new version to become active.'
        Sleep 2
      }
    }
    if ($newInstalledVersion -ne $desiredVersion) {
      Write-Output """New version does not appear to be desired version: ${newInstalledVersion}"""
      # Put the old version of RightLink back because something seemed to have gone wrong
      Rename-Item -Path ${RIGHTLINK_DIR}\rightlink.exe -newName 'rightlink-new.exe' -Force
      Rename-Item -Path ${RIGHTLINK_DIR}\rightlink-old.exe -newName 'rightlink.exe' -Force
      # Stop the new rightlink process so that we revert back to the old version when NSSM restarts RightLink
      Stop-Process -Name 'rightlink' -Force
      Exit 1
    }

    # Report to audit entry that RightLink upgraded.
    $instanceHref = & ${RIGHTLINK_DIR}\rsc.exe --rl10 --x1 ':has(.rel:val(\"\"\"self\"\"\")).href' `
                    cm15 index_instance_session /api/sessions/instance 2> $null
    if ($instanceHref) {
      $auditEntryHref = & ${RIGHTLINK_DIR}\rsc.exe --rl10 --xh 'location' cm15 create /api/audit_entries `
                        """audit_entry[auditee_href]=${instanceHref}""" `
                        """audit_entry[detail]=RightLink updated to '${newInstalledVersion}'""" `
                        """audit_entry[summary]=RightLink updated""" 2> $null
      if ($auditEntryHref) {
        Write-Output """Audit entry created at ${auditEntryHref}"""
      } else {
        Write-Output 'Failed to create audit entry'
      }
    } else {
      Write-Output 'Unable to obtain instance HREF for audit entries'
    }
  }
}

$RIGHTLINK_DIR = 'C:\Program Files\RightScale\RightLink'

if (!$env:UPGRADES_FILE_LOCATION) {
  $env:UPGRADES_FILE_LOCATION = 'https://rightlink.rightscale.com/rightlink/upgrades'
}

# Query RightLink info
$json = & "${RIGHTLINK_DIR}\rsc.exe" rl10 index /rll/proc

# Determine current version of rightlink
$currentVersion = Write-Output $json | & "${RIGHTLINK_DIR}\rsc.exe" --x1 .version json 2> $null

if (!$currentVersion) {
  Write-Output 'Cannot determine current version of RightLink'
  Exit 1
}

# Fetch information about what we should become. The "upgrades" file consists of lines formatted
# as "currentVersion:desiredVersion". If the "upgrades" file does not exist,
# or if the current version is not in the file, no upgrade is done.
$desiredVersion = (New-Object System.Net.WebClient).DownloadString($env:UPGRADES_FILE_LOCATION) -Split "`n" |
                  Select-String "^\s*${currentVersion}\s*:\s*(\S+)\s*$" | % { $_.Matches.Groups[1].Value }

if (!$desiredVersion) {
  Write-Output 'Cannot determine latest version from upgrade file'
  Write-Output "Tried to match /^${currentVersion}:/ in ${env:UPGRADES_FILE_LOCATION}"
  Exit 0
}

if ($desiredVersion -eq $currentVersion) {
  Write-Output "RightLink is already up-to-date (current = ${currentVersion})"
  Exit 0
}

Write-Output 'RightLink needs update:'
Write-Output "  from current = ${currentVersion}"
Write-Output "  to   desired = ${desiredVersion}"

Write-Output "Downloading RightLink version '${desiredVersion}'"

# Download new version
$TMP_DIR = 'C:\Windows\Temp\Upgrade'
$RIGHTLINK_URL = "https://rightlink.rightscale.com/rll/${desiredVersion}/rightlink.zip"

# If temp directory doesn't exist then create it
if (!(Test-Path -Path $TMP_DIR)) {
  New-Item -Path $TMP_DIR -Type Directory | Out-Null
}

# Delete old RightLink folder and Archive in temp directory if they exist before downloading new version
if (Test-Path -Path ${TMP_DIR}\rightlink) {
  Remove-Item "${TMP_DIR}\rightlink" -Force -Recurse
}
if (Test-Path -Path ${TMP_DIR}\rightlink.zip) {
  Remove-Item "${TMP_DIR}\rightlink.zip" -Force
}

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($RIGHTLINK_URL, "${TMP_DIR}\rightlink.zip")

# Expand the archive into C:\Temp\Upgrade
Expand-Zipfile "${TMP_DIR}\rightlink.zip" $TMP_DIR | Out-Null

# Check downloaded version
if (Test-Path -Path ${RIGHTLINK_DIR}\rightlink-new.exe) {
  Remove-Item "${RIGHTLINK_DIR}\rightlink-new.exe" -Force
}
Move-Item -Path "${TMP_DIR}\RightLink\rightlink.exe" -Destination "${RIGHTLINK_DIR}\rightlink-new.exe" -Force
Write-Output 'Checking new version'
$newVersion = & "${RIGHTLINK_DIR}\rightlink-new.exe" --version | % { $_.Split(" ")[1] }

if ($newVersion -eq $desiredVersion) {
  Write-Output "New version looks right: ${newVersion}"
  Write-Output 'Restarting RightLink to pick up new version'
  # Fork a new task since this main process is started by RightLink and we are restarting it.
  Start-Process Powershell -ArgumentList "-Command & { $upgradeFunction upgradeRightLink ${currentVersion} ${desiredVersion} }"
} else {
  Write-Output "Updated version does not appear to be desired version: ${newVersion}"
  Exit 1
}
