# ---
# RightScript Name: RL10 Windows Setup Hostname
# Description: Changes the hostname of the server.
# Inputs:
#   SERVER_HOSTNAME:
#     Input Type: single
#     Category: RightScale
#     Description: The server's hostname may contain letters (a-z, A-Z), numbers (0-9), and hyphens (-),
#       but no spaces or periods (.). The name may not consist entirely of digits, and may not be longer
#       than 63 characters.
#     Default: text
#     Required: false
#     Advanced: true
#   WINDOWS_UPDATES_REBOOT_SETTING:
#     Input Type: single
#     Category: RightScale
#     Description: Setting whether to reboot automatically.
#     Default: text:Do Not Allow Reboot
#     Required: false
#     Advanced: true
#     Possible Values:
#       - text:Do Not Allow Reboot
#       - text:Allow Reboot
# ...
#

$ErrorActionPreference = 'Stop'

# The server's hostname is set to the ServerTemplate input SERVER_HOSTNAME
# If SERVER_HOSTNAME is empty, will maintain current hostname.
# Standard names may contain letters (a-z, A-Z), numbers (0-9), and hyphens (-),
# but no spaces or periods (.). The name may not consist entirely of digits, and
# may not be longer than 63 characters.

if ($env:SERVER_HOSTNAME -and $env:SERVER_HOSTNAME -ne (& hostname)) {
  Rename-Computer $env:SERVER_HOSTNAME

  # Host Name does not take effect until after a computer restart
  if ($env:WINDOWS_UPDATES_REBOOT_SETTING -eq 'Allow Reboot') {
    Restart-Computer -Force
  } else {
    return 'Reboot is required, but not allowed by WINDOWS_UPDATES_REBOOT_SETTING input. Please do the reboot manually.'
  }
}
