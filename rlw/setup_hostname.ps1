$ErrorActionPreference = 'Stop'

# The server's hostname is set to the ServerTemplate input SERVER_HOSTNAME
# If SERVER_HOSTNAME is empty, will maintain current hostname.
# Standard names may contain letters (a-z, A-Z), numbers (0-9), and hyphens (-),
# but no spaces or periods (.). The name may not consist entirely of digits, and
# may not be longer than 63 characters.

if ($env:SERVER_HOSTNAME -and $env:SERVER_HOSTNAME -ne (& hostname)) {
  Rename-Computer $env:SERVER_HOSTNAME

  # Host Name does not take effect until after a computer restart
  if ($env:WINDOWS_UPDATES_REBOOT_SETTING -eq "Allow Reboot") {
    Restart-Computer -Force
  } else {
    return "Reboot is required, but not allowed by WINDOWS_UPDATES_REBOOT_SETTING input. Please do the reboot manually."
  }
}
