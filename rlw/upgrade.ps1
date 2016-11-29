# ---
# RightScript Name: RL10 Windows Upgrade
# Description: Check whether a RightLink upgrade is available and perform the upgrade.
# Inputs:
#   UPGRADE_VERSION:
#     Input Type: single
#     Category: RightScale
#     Description: Check whether a RightLink upgrade is available and perform the upgrade.
#     Default: blank
#     Required: true
#     Advanced: true
# ...
#

$upgradeFunction = {
  function upgradeRightLink($currentVersion, $desiredVersion) {
    # Give the rightscript process this was called from time to finish
    Sleep 5

    $RIGHTLINK_DIR = """${env:ProgramFiles}\RightScale\RightLink"""
    $TMP_DIR = """${env:TEMP}\Upgrade"""
    # Determine if the version of rsc supports retry
    $retryCommand = ('',('--retry=5 --timeout=60' -split ' '))[[String](& ${RIGHTLINK_DIR}\rsc.exe --help) -match 'retry']

    # The self-upgrade API call doesn't actually upgrade the executable on Windows, but it does flush out audit entries
    # and test connectivity.
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
      $newInstalledVersion = & ${RIGHTLINK_DIR}\rsc.exe $retryCommand rl10 show /rll/proc/version 2> $null
      if ($newInstalledVersion -eq $desiredVersion) {
        Write-Output """New version active - ${newInstalledVersion}"""
        break
      } else {
        Write-Output 'Waiting for new version to become active.'
        Sleep 5
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
    $instanceHref = & ${RIGHTLINK_DIR}\rsc.exe $retryCommand --rl10 --x1 ':has(.rel:val(\"\"\"self\"\"\")).href' `
                    cm15 index_instance_session /api/sessions/instance 2> $null
    if ($instanceHref) {
      $auditEntryHref = & ${RIGHTLINK_DIR}\rsc.exe $retryCommand --rl10 --xh 'location' cm15 create /api/audit_entries `
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

    # Update RSC after RightLink has successfully updated.
    if (Test-Path -Path ${RIGHTLINK_DIR}\rsc.exe) {
      Rename-Item -Path ${RIGHTLINK_DIR}\rsc.exe -newName 'rsc-old.exe' -Force
    }
    Move-Item -Path ${TMP_DIR}\RightLink\rsc.exe -Destination ${RIGHTLINK_DIR}\rsc.exe -Force
    # If new RSC is correctly installed then remove the old version
    if (Test-Path -Path ${RIGHTLINK_DIR}\rsc.exe) {
      Remove-Item -Path ${RIGHTLINK_DIR}\rsc-old.exe -Force
    } else {
      Write-Output 'Failed to update to new version of RSC'
      Rename-Item -Path ${RIGHTLINK_DIR}\rsc-old.exe -newName 'rsc.exe' -Force
    }
  }
}

$RIGHTLINK_DIR = "$env:ProgramFiles\RightScale\RightLink"
$RS_ID_FILE = "$env:ProgramData\RightScale\RightLink\rightscale-identity"

# Determine if the version of rsc supports retry. The upgrades script can be called
# as an any script and RL may have an older rsc bundled with it.
$retryCommand = ('',('--retry=5 --timeout=60' -split ' '))[[String](& ${RIGHTLINK_DIR}\rsc.exe --help) -match 'retry']

# Determine current version of rightlink
$currentVersion = & "${RIGHTLINK_DIR}\rsc.exe" $retryCommand rl10 show /rll/proc/version 2> $null

if ([string]::IsNullOrEmpty($currentVersion)) {
  Write-Output 'Cannot determine current version of RightLink'
  Exit 1
}

$desiredVersion = $env:UPGRADE_VERSION

if ([string]::IsNullOrEmpty($desiredVersion)) {
  Write-Output 'No upgrade version supplied'
  Exit 1
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
$TMP_DIR = "$env:TEMP\Upgrade"
$RIGHTLINK_URL = "https://rightlink.rightscale.com/rll/${desiredVersion}/rightlink.zip"
$7ZIP = "${TMP_DIR}\7za.exe"
$7ZIP_URL = 'https://rightlink.rightscale.com/rll/7zip/7za.exe'

# If temp directory doesn't exist then create it
if (!(Test-Path -Path $TMP_DIR)) {
  New-Item -Path $TMP_DIR -Type Directory | Out-Null
}

# Delete old RightLink folder and Archive in temp directory if they exist before downloading new version
if (Test-Path -Path ${TMP_DIR}\rightlink) {
  Remove-Item "${TMP_DIR}\RightLink" -Force -Recurse
}
if (Test-Path -Path ${TMP_DIR}\rightlink.zip) {
  Remove-Item "${TMP_DIR}\rightlink.zip" -Force
}

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($RIGHTLINK_URL, "${TMP_DIR}\rightlink.zip")

# Due to an bug in Windows 2008R2 being unable to copy files from a zip when powershell is run through a service,
# We download 7-zip, a command line unzipping tool to expand the new version of RightLink10

if (Test-Path -Path $7ZIP) {
  Remove-Item "${TMP_DIR}\7za.exe" -Force
}
$wc.DownloadFile($7ZIP_URL, $7ZIP)

# Expand the archive into C:\Temp\Upgrade
& ${7ZIP} x "${TMP_DIR}\rightlink.zip" "-o${TMP_DIR}" -r -y | Out-Null

# Check downloaded version
if (Test-Path -Path ${RIGHTLINK_DIR}\rightlink-new.exe) {
  Remove-Item "${RIGHTLINK_DIR}\rightlink-new.exe" -Force
}
Move-Item -Path "${TMP_DIR}\RightLink\rightlink.exe" -Destination "${RIGHTLINK_DIR}\rightlink-new.exe" -Force
Write-Output 'Checking new version'
$newVersion = & "${RIGHTLINK_DIR}\rightlink-new.exe" --version | % { $_.Split(" ")[1] }

if ($newVersion -eq $desiredVersion) {
  Write-Output "New version looks right: ${newVersion}"

  # Do an initial self-check as we can't get status after we fork off the background process.
  foreach ($line in (Get-Content $RS_ID_FILE)) {
    if ($line -match '^([^=]+)=(.+)$') {
      [environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
  }
  $selfCheckOutput =  & "${RIGHTLINK_DIR}\rightlink-new.exe" --selfcheck 2>&1
  if ($selfCheckOutput -match "Self-check succeeded") {
    Write-Output "New version passed connectivity check"
  } else {
    Write-Output "Initial self-check failed:"
    Write-Output "$selfCheckOutput"
    Exit 1
  }

  Write-Output 'Restarting RightLink to pick up new version'
  # Fork a new task since this main process is started by RightLink and we are restarting it.
  Start-Process Powershell -ArgumentList "-Command & { $upgradeFunction upgradeRightLink ${currentVersion} ${desiredVersion} }"
} else {
  Write-Output "Updated version does not appear to be desired version: ${newVersion}"
  Exit 1
}
