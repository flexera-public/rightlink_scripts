# On AWS, if an elastic IP address is specified this script will wait until all API Hosts are
# reporting the expected IP address for the server, which is recorded in the user-data

$RS_DIR = "C:\ProgramData\RightScale\RightLink"
$RS_ID_FILE = "$RS_DIR\rightscale-identity"

foreach ($line in (Get-Content $RS_ID_FILE)) {
  if ($line -match 'expected_public_ip=(.+)') {
    $expectedPublicIP = $matches[1]
  } elseif ($line -match 'api_hostname=(.+)') {
    $apiHostname = $matches[1]
  }
}

if (!$expectedPublicIP) {
  Write-Output "No public IP address to wait for"
  Exit 0
}

$rfc1918 = "^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)"
if ($expectedPublicIP -match $rfc1918) {
  Write-Output "External IP is within rfc1918 range: $expectedPublicIP, not waiting"
  Exit 0
}
Write-Output "Expecting to be assigned public IP $expectedPublicIP"

$targets = @("my.rightscale.com", "us-3.rightscale.com", "us-4.rightscale.com", "island1.rightscale.com", "island10.rightscale.com", $api_hostname)
Write-Output "Checking public IP against $targets"

# spend at most 15 minutes checking the API hosts for either the expected IP address or an incorrect IP address
$startTime = Get-Date
$wc = New-Object System.Net.WebClient
while ((New-TimeSpan -Start $startTime -End (Get-Date)).TotalSeconds -lt 900) {
  # reset matching API responses to zero
  $matchingResponses = 0
  # reset array of target API Hosts returned bad IPs
  $badIPs = @()
  # check each API
  foreach ($target in $targets) {
    $myIP = $wc.DownloadString("http://$target/ip/mine")
    if ($myIP -match "^[.0-9]+$" -and $myIP -notmatch "^127\." -and $myIP -notmatch $expectedPublicIP) {
      Write-Output "$target responded with: $myIP which is not the IP we expect: $expectedPublicIP"
      $badIPs += $target
    } elseif ($myIP -eq $expectedPublicIP) {
      $matchingResponses += 1
    } else {
      Write-Output "$target responded with $myIP"
    }
  }
  # check to see if all API hosts reported IPs that match the expected IP and exit the script
  if ($matchingResponses -eq $targets.Length) {
    Write-Output "All API hosts are reporting the expected IP address: $expectedPublicIP"
    Exit 0
  } else {
    Write-Output "The follow API Hosts are returning an IP address that is different than expected: $badIPs"
    Write-Output "Sleeping 15 seconds and retrying ... "
    sleep 15
  }
}

# if any API hosts are returning something other than the expected IP address after 15 minutes then exit with an error
[int]$totalTime = (New-TimeSpan -Start $startTime -End (Get-Date)).TotalSeconds
Write-Output "The follow API Hosts are returning an IP address that is different than expected after $totalTime seconds: $badIPs"
Exit 1
