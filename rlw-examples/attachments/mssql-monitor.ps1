while ($True) {
  $nowT = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))
  $res =  Get-WmiObject -Query "select Buffercachehitratio from Win32_PerfFormattedData_MSSQLSERVER_SQLServerBufferManager"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/buffer-cache-hit-ratio interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.Buffercachehitratio)"
  }

  $res = Get-WmiObject -Query "select PercentPrivilegedTime, PercentProcessorTime, PercentInterruptTime from Win32_PerfFormattedData_PerfOS_Processor Where Name='0'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/cpu-0/percent_privileged_time_0 interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PercentPrivilegedTime)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/cpu-0/percent_processor_time_0 interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PercentProcessorTime)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/cpu-0/percent_interrupt_time_0 interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PercentInterruptTime)"
  }

  $res = Get-WmiObject -Query "select LogBytesFlushedPersec, LogCacheHitRatio, LogCacheReadsPersec, LogFlushWaitTime, LogFlushWaitsPersec, LogFlushesPersec, PercentLogUsed, TransactionsPersec from Win32_PerfFormattedData_MSSQLSERVER_SQLServerDatabases"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/log-bytes-flushed-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogBytesFlushedPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/log-cache-hit-ratio interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogCacheHitRatio)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/log-cache-reads-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogCacheReadsPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/log-flush-wait-time interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogFlushWaitTime)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/log-flush-waits-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogFlushWaitsPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/log-flushes-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogFlushesPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/percent-log-used interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PercentLogUsed)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/transactions-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.TransactionsPersec)"
  }

  $res =  Get-WmiObject -Query "select AvgDiskQueueLength, AvgDisksecPerRead, AvgDiskReadQueueLength, AvgDisksecPerTransfer, AvgDiskWriteQueueLength, DiskWritesPersec from Win32_PerfFormattedData_PerfDisk_PhysicalDisk where name= '_Total'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/average_disks_queue_length interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDiskQueueLength)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/average_disks_sec_per_read interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerRead)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/average_disks_read_queue_length interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDiskReadQueueLength)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/average_disks_sec_per_transfer interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerTransfer)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/average_disks_write_queue_length interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDiskWriteQueueLength)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/disks_writes_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.DiskWritesPersec)"
  }

  $res =  Get-WmiObject -Query "select AvgDisksecPerRead, AvgDisksecPerWrite from Win32_PerfFormattedData_PerfDisk_LogicalDisk WHERE Name='c:'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/logical-disks/avg_disk_sec_per_read_c interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerRead)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/logical-disks/avg_disk_sec_per_write_c interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerWrite)"
  }


  $res =  Get-WmiObject -Query "select AvgDisksecPerRead, AvgDisksecPerWrite from Win32_PerfFormattedData_PerfDisk_LogicalDisk WHERE Name='d:'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/logical-disks/avg_disk_sec_per_read_d interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerRead)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/logical-disks/avg_disk_sec_per_write_d interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerWrite)"
  }

  $res =  Get-WmiObject -Query "select AvgDisksecPerRead, AvgDisksecPerWrite from Win32_PerfFormattedData_PerfDisk_LogicalDisk WHERE Name='e:'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/logical-disks/avg_disk_sec_per_read_e interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerRead)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/logical-disks/avg_disk_sec_per_write_e interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerWrite)"
  }

  $res =  Get-WmiObject -Query "select CacheBytes, CacheFaultsPersec, PageReadsPersec, PagesPersec, PoolNonpagedBytes from Win32_PerfFormattedData_PerfOS_Memory"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/memory/cache_bytes interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.CacheBytes)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/memory/cache_faults_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.CacheFaultsPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/memory/page_reads_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PageReadsPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/memory/pages_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PagesPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/memory/pool_nonpaged_bytes interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PoolNonpagedBytes)"
  }

  $res =  Get-WmiObject -Query "select LogBytesSentPersec, LogSendQueueKB, RedoBytesPersec, RedoQueueKB, TransactionDelay from Win32_PerfFormattedData_MSSQLSERVER_SQLServerDatabaseMirroring where Name='_Total'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/log-bytes-sent-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogBytesSentPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/log-send-queue-kb interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogSendQueueKB)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/redo-bytes-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.RedoBytesPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/redo-queue-kb interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.RedoQueueKB)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/transaction-delay interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.TransactionDelay)"
  }
  $res =  Get-WmiObject -Query "select State from RS_SQLSTATE"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/mirroring-state interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.State)"
  }


  $res =  Get-WmiObject -Query "select NumberofDeadlocksPersec from Win32_PerfFormattedData_MSSQLSERVER_SQLServerLocks"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/deadlocks-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.NumberofDeadlocksPersec)"
  }

  $res =  Get-WmiObject -Query "select PageSplitsPersec from Win32_PerfFormattedData_MSSQLSERVER_SQLServerAccessMethods"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/page-splits-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PageSplitsPersec)"
  }


  $res =  Get-WmiObject -Query "select BytesTotalPersec, PoolNonpagedFailures, PoolNonpagedPeak, PoolPagedFailures from Win32_PerfFormattedData_PerfNet_Server"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/server/bytes_total_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.BytesTotalPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/server/pool_non_paged_failures interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PoolNonpagedFailures)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/server/pool_non_paged_peak interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PoolNonpagedPeak)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/server/pool_paged_peak interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PoolPagedFailures)"
  }

  $res =  Get-WmiObject -Query "select BatchRequestsPersec, SQLCompilationsPersec from Win32_PerfFormattedData_MSSQLSERVER_SQLServerSQLStatistics"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/batch-requests-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.BatchRequestsPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/sql-compilations-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.SQLCompilationsPersec)"
  }

  $res =  Get-WmiObject -Query "select ContextSwitchesPersec, ProcessorQueueLength from Win32_PerfFormattedData_PerfOS_System"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/system/context_switches_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.ContextSwitchesPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/system/processor_queue_length interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.ProcessorQueueLength)"
  }

  $res =  Get-WmiObject -Query "select ThreadCount from Win32_PerfFormattedData_PerfProc_Process where Name='sqlservr'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/threads interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.ThreadCount)"
  }


  $res =  Get-WmiObject -Query "select UserConnections from Win32_PerfFormattedData_MSSQLSERVER_SQLServerGeneralStatistics"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/user-connections interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.UserConnections)"
  }

  $res =  Get-WmiObject -Query "select ThreadCount from Win32_PerfFormattedData_PerfProc_Process where Name='sqlwriter'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/writer-threads interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.ThreadCount)"
  }

  Sleep $Env:COLLECTD_INTERVAL
}
