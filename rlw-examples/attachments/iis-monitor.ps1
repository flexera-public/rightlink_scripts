# Collect following metrics using WMI queries:
# -IIS Anonymous Users per Second
# -IIS Connection Attempts per Second
# -IIS Current Connections
# -IIS Get Requests per Second
# -IIS Logon Attempts per Second
# -IIS Non-Anonymous Users per Second
# -IIS Not Found Errors per Second
# -IIS Post Requests per Second
# -IIS Total Bytes Received
# -IIS Total Bytes Sent
# -IIS Inetinfo Handle Count
# -IIS Inetinfo Percent Processor Time
#
# Data is passed back to TSS in plain text protocol similar to one used in Exec plugin for collectd
# (see https://collectd.org/wiki/index.php/Plain_text_protocol#PUTVAL)

while ($True) {
  $nowT = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))

  # Collecting following inforamtion from raw data from performance counters that monitor the World Wide Web Publishing Service:
  #  - Rate at which bytes are received/sent by the web service
  #  - Rate at which all HTTP requests are made
  #  - Total number of users who established an anonymous connection with the web service (counted after service startup)
  #  - Total number of users who established a non-anonymous connection with the web service (counted after service startup)
  #  - Number of connections that have been attempted using the web service (counted after service startup)
  #  - Number of requests that cannot be satisfied by the server because the requested document could not be found (counted after service startup)
  #  - Number of logons that have been attempted using the web service (counted after service startup)
  # see: https://msdn.microsoft.com/en-us/library/aa394345(v=vs.85).aspx
  $res =  Get-WmiObject -Query "Select * from Win32_PerfRawData_W3SVC_WebService where Name='_Total'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/IIS/counter-iis_bytes-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.BytesReceivedPerSec):$($res.BytesSentPerSec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/IIS/counter-requests-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.TotalMethodRequests)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/IIS/counter-anonymous-users interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.TotalAnonymousUsers)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/IIS/counter-non-anonymous-users interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.TotalNonAnonymousUsers)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/IIS/counter-connection-attempts interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.TotalConnectionAttemptsallinstances)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/IIS/counter-not-found-errors interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.TotalNotFoundErrors)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/IIS/counter-logon-attempts interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.TotalLogonAttempts)"
  }


  # Collecting following info from raw data from performance counters that monitor IIS worker process:
  #  - Elapsed time that all of the threads of this process used the processor to execute instructions in 100 nanoseconds ticks
  #  - Number of threads currently active in this process
  # see: https://msdn.microsoft.com/en-us/library/aa394323(v=vs.85).aspx and https://technet.microsoft.com/en-us/library/cc735084(v=ws.10).aspx
  $res = Get-WmiObject -Query "Select PercentProcessorTime, ThreadCount from Win32_PerfRawData_PerfProc_Process where name='w3wp'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/IIS/counter-w3wp-percent-processor-time interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PercentProcessorTime)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/IIS/gauge-w3wp-thread-count interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.ThreadCount)"
  }
  Sleep $Env:COLLECTD_INTERVAL
}
