$ErrorActionPreference = 'Stop'

# The server's hostname is set to the ServerTemplate input SERVER_HOSTNAME
# If SERVER_HOSTNAME is empty, will maintain current hostname.
# Standard names may contain letters (a-z, A-Z), numbers (0-9), and hyphens (-),
# but no spaces or periods (.). The name may not consist entirely of digits, and
# may not be longer than 63 characters.

if ($env:SERVER_HOSTNAME -and $env:SERVER_HOSTNAME -ne (& hostname)) {
  Rename-Computer $env:SERVER_HOSTNAME

  # Host Name does not take effect until after a computer restart
  Restart-Computer -Force
}
