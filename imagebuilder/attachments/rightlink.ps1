Write-Output "Setting LocalAccountTokenFilterPolicy"
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name LocalAccountTokenFilterPolicy -Type DWord -Value 1

######################################################################

Write-Output "Creating WinRM SSL firewall rule"
netsh advfirewall firewall add rule name="RightScale WinRM" remoteip=any localport=5986 action=allow protocol=TCP dir=in

######################################################################

Write-Output 'Installing RightLink...'
$filename = "rightlink.install.ps1";
$link = "https://rightlink.rightscale.com/rll/%%RIGHTLINK_VERSION%%/$filename";
$dstDir = "$env:temp";
$remotePath = Join-Path $dstDir $filename;
$client = New-Object System.Net.Webclient
$client.Proxy = $null 
$client.downloadfile($link, $remotePath);
Invoke-Expression -Command $remotePath