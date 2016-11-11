# ---
# RightScript Name: RL10 Windows Setup NTP
# Description: |-
#   The script is used to configure Windows W32Time/NTP time settings on the server it is run against. The script
#   is defaulted to the same settings configured in RightScale Windows RightImages (time.rightscale.com). This
#   script can be used to update the image defaults as needed for private cloud.
# 
#   This script will do the following:
#   1. Start Windows Time service
#   2. If the server is a member of a domain it will configure the server for Automatic Domain Time Synchronization
#   3. If the server is standalone update the NTP server and polling interval settings.
# Inputs:
#   SETUP_NTP:
#     Category: RightScale
#     Description: |
#       Whether or not to configure NTP. "if_missing" only configures NTP if its not already setup by a service such as
#       DHCP while "always" will overwrite any existing configuration.
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: text:if_missing
#     Possible Values:
#       - text:always
#       - text:if_missing
#       - text:none
#   NTP_SERVER:
#     Category: System
#     Description: 'FQDN or IP address of NTP server to be used for time sync. Example:text:time.rightscale.com.'
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: text:time.rightscale.com
# Attachments: []
# ...

# Stop and fail script when a command fails.
$errorActionPreference = "Stop"

if ($env:SETUP_NTP -eq "none") {
    Write-Host "Not configuring NTP: SETUP_NTP is none"
    exit 0
}

if ($env:NTP_SERVER -eq "") {
    Write-Host "Not configuring NTP: No NTP server specified"
    exit 0
}

if ((Get-Service w32time).Status -ne "Running")
{
    Write-Host "Starting time service."
    Start-Service w32time
    $timeout = 0
    while ((Get-Service w32time).Status -ne "Running")
    {
        Start-Sleep -Seconds 5
        $timeout += 5
        if ($timeout -gt 60)
        {
            Write-Error "Error starting time service. Please check the event log to identify root cause of the issue."
            exit 1
        }
    }
}

if ((Get-WmiObject Win32_ComputerSystem).PartOfDomain -eq $True) 
{ 
    Write-Host "Updating NTP settings for automatic domain time synchronization." 
    w32tm /config /syncfromflags:domhier /update
    Write-Host "Restarting time service."
    Restart-Service w32time
}
else
{
    if ($env:SETUP_NTP -eq "if_missing") {
        $existing = gp 'HKLM:\SYSTEM\CurrentControlSet\services\W32Time\Parameters'
        if (($existing.NtpServer -NotMatch "time.windows.com") -and ($existing.NtpServer -Match "0x")) {
            Write-Host "Skipping configuration, found existing NTP server: $($existing.NtpServer)"
            exit 0            
        }
    }

    $ntpServer = $env:NTP_SERVER
    $pollInterval = "900"
    Write-Host "Setting NTP server to '$ntpServer', poll interval to ${pollInterval} seconds."

    sp 'HKLM:\SYSTEM\CurrentControlSet\services\W32Time\Parameters' 'NtpServer' "${ntpServer},0x01"
    sp 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient' 'SpecialPollInterval' $pollInterval
    sp 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config' 'AnnounceFlags' 5 
    sp 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' 'Type' 'NTP'
    sp 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers' '6' $ntpServer
    sp 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers' '(Default)' 6
    
    Write-Host "Updating time service config."
    w32tm /config /update
    Write-Host "Restarting time service."
    Restart-Service w32time
}    
