# Collects various information about MS SQL server and system it runs on.
#
# Data is passed back to TSS in plain text protocol similar to one used in Exec plugin for collectd
# (see https://collectd.org/wiki/index.php/Plain_text_protocol#PUTVAL)

while ($True) {
  $nowT = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))

  # Collecting the percentage of pages found in the buffer cache without having to read from disk
  # see: https://technet.microsoft.com/en-us/library/ms189628(v=sql.110).aspx
  $res =  Get-WmiObject -Query "select Buffercachehitratio from Win32_PerfFormattedData_MSSQLSERVER_SQLServerBufferManager"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-buffer-cache-hit-ratio interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.Buffercachehitratio)"
  }

  # Collecting following data from performance counters that monitor aspects of processor activity:
  #  - Percentage of non-idle processor time spent in privileged mode
  #  - Percentage of time that the processor is executing a non-idle thread.
  #  - Percentage of time that the processor spent receiving and servicing hardware interrupts during the sample interval.
  # see: https://msdn.microsoft.com/en-us/library/aa394271(v=vs.85).aspx
  $res = Get-WmiObject -Query "select PercentPrivilegedTime, PercentProcessorTime, PercentInterruptTime from Win32_PerfFormattedData_PerfOS_Processor Where Name='0'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/cpu-0/gauge-percent_privileged_time_0 interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PercentPrivilegedTime)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/cpu-0/gauge-percent_processor_time_0 interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PercentProcessorTime)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/cpu-0/gauge-percent_interrupt_time_0 interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PercentInterruptTime)"
  }

  # Collecting following information:
  #  - Total number of log bytes flushed per second
  #  - Percentage of log cache reads satisfied from the log cache
  #  - Reads performed per second through the log manager cache
  #  - Total wait time (in milliseconds) to flush the log
  #  - Number of commits per second waiting for the log flush
  #  - Number of log flushes per second
  #  - Percentage of space in the log that is in use
  #  - Number of transactions started for the database per second
  # see: https://msdn.microsoft.com/en-us/library/ms189883.aspx
  $res = Get-WmiObject -Query "select LogBytesFlushedPersec, LogCacheHitRatio, LogCacheReadsPersec, LogFlushWaitTime, LogFlushWaitsPersec, LogFlushesPersec, PercentLogUsed, TransactionsPersec from Win32_PerfFormattedData_MSSQLSERVER_SQLServerDatabases"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-log-bytes-flushed-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogBytesFlushedPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-log-cache-hit-ratio interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogCacheHitRatio)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-log-cache-reads-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogCacheReadsPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-log-flush-wait-time interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogFlushWaitTime)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-log-flush-waits-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogFlushWaitsPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-log-flushes-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogFlushesPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-percent-log-used interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PercentLogUsed)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-transactions-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.TransactionsPersec)"
  }

  # Collecting following information about hard or fixed disk drive:
  #  - Average number of both read and write requests that were queued for the selected disk during the sample interval.
  #  - Average time, in seconds, of a read of data from the disk.
  #  - Average number of read requests that were queued for the selected disk during the sample interval.
  #  - Time, in seconds, of the average disk transfer.
  #  - Average number of write requests that were queued for the selected disk during the sample interval. The time base is 100 nanoseconds.
  #  - Rate of write operations on the disk.
  # see: https://msdn.microsoft.com/en-us/library/aa394262(v=vs.85).aspx
  $res =  Get-WmiObject -Query "select AvgDiskQueueLength, AvgDisksecPerRead, AvgDiskReadQueueLength, AvgDisksecPerTransfer, AvgDiskWriteQueueLength, DiskWritesPersec from Win32_PerfFormattedData_PerfDisk_PhysicalDisk where name= '_Total'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/gauge-average_disks_queue_length interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDiskQueueLength)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/gauge-average_disks_sec_per_read interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerRead)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/gauge-average_disks_read_queue_length interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDiskReadQueueLength)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/gauge-average_disks_sec_per_transfer interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerTransfer)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/gauge-average_disks_write_queue_length interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDiskWriteQueueLength)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/df/gauge-disks_writes_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.DiskWritesPersec)"
  }

  # Collecting average time, in seconds, of a read/write operation of data from the disk(for each logical disk)
  # see: https://msdn.microsoft.com/en-us/library/aa394261(v=vs.85).aspx
  foreach ($drive in 'c', 'd', 'e') {
    $res =  Get-WmiObject -Query "select AvgDisksecPerRead, AvgDisksecPerWrite from Win32_PerfFormattedData_PerfDisk_LogicalDisk WHERE Name='$drive:'"
    if ($res) {
      Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/logical-disks/gauge-avg_disk_sec_per_read_$drive interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerRead)"
      Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/logical-disks/gauge-avg_disk_sec_per_write_$drive interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.AvgDisksecPerWrite)"
    }
  }

  # Collecting following data from performance counters that monitor the physical and virtual memory on the computer:
  #  - Number of bytes currently being used by the file system cache
  #  - Number of faults which occur when a page is not found in the file system cache and must be retrieved from elsewhere in memory (a soft fault) or from disk (a hard fault)
  #  - Number of times the disk was read to resolve hard page faults.
  #  - Number of pages read from or written to the disk to resolve hard page faults.
  #  - Number of bytes in the nonpaged pool, an area of system memory (physical memory used by the operating system) for objects that cannot be written to disk, but must remain in physical memory as long as they are allocated.
  # see: https://msdn.microsoft.com/en-us/library/aa394268(v=vs.85).aspx
  $res =  Get-WmiObject -Query "select CacheBytes, CacheFaultsPersec, PageReadsPersec, PagesPersec, PoolNonpagedBytes from Win32_PerfFormattedData_PerfOS_Memory"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/memory/gauge-cache_bytes interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.CacheBytes)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/memory/gauge-cache_faults_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.CacheFaultsPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/memory/gauge-page_reads_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PageReadsPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/memory/gauge-pages_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PagesPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/memory/gauge-pool_nonpaged_bytes interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PoolNonpagedBytes)"
  }

  # Collecting following information about SQL Server database mirroring:
  #  - Number of bytes of log sent per second.
  #  - Total number of kilobytes of log that have not yet been sent to the mirror server
  #  - Number of bytes of log rolled forward on the mirror database per second
  #  - Total number of kilobytes of hardened log that currently remain to be applied to the mirror database to roll it forward
  #  - Delay in waiting for unterminated commit acknowledgement
  # see: https://msdn.microsoft.com/en-us/library/ms189931.aspx
  $res =  Get-WmiObject -Query "select LogBytesSentPersec, LogSendQueueKB, RedoBytesPersec, RedoQueueKB, TransactionDelay from Win32_PerfFormattedData_MSSQLSERVER_SQLServerDatabaseMirroring where Name='_Total'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/gauge-log-bytes-sent-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogBytesSentPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/gauge-log-send-queue-kb interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.LogSendQueueKB)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/gauge-redo-bytes-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.RedoBytesPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/gauge-redo-queue-kb interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.RedoQueueKB)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server-mirroring/gauge-transaction-delay interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.TransactionDelay)"
  }

  # Collecting number of lock requests per second that resulted in a deadlock
  # see: https://msdn.microsoft.com/en-us/library/ms190216.aspx
  $res =  Get-WmiObject -Query "select NumberofDeadlocksPersec from Win32_PerfFormattedData_MSSQLSERVER_SQLServerLocks"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-deadlocks-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.NumberofDeadlocksPersec)"
  }

  # Collecting number of page splits per second that occur as the result of overflowing index pages
  # see: https://technet.microsoft.com/en-us/library/aa905154(v=sql.80).aspx
  $res =  Get-WmiObject -Query "select PageSplitsPersec from Win32_PerfFormattedData_MSSQLSERVER_SQLServerAccessMethods"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-page-splits-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PageSplitsPersec)"
  }

  # Collecting following data from performance counters that monitor communications using the WINS Server service:
  #  - Number, in bytes, that the server has sent to and received from the network, an overall indication of busy the server is.
  #  - Number of times allocations from nonpaged pool have failed. Indicates that the computer's physical memory is too small.
  #  - Maximum number, in bytes, of nonpaged pool the server has had in use at any one point. Indicates how much physical memory the computer should have.
  #  - Number of times allocations from paged pool have failed. Indicates that the computer's physical memory or paging file are too small.
  # see: https://msdn.microsoft.com/en-us/library/aa394265(v=vs.85).aspx
  $res =  Get-WmiObject -Query "select BytesTotalPersec, PoolNonpagedFailures, PoolNonpagedPeak, PoolPagedFailures from Win32_PerfFormattedData_PerfNet_Server"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/server/gauge-bytes_total_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.BytesTotalPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/server/gauge-pool_non_paged_failures interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PoolNonpagedFailures)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/server/gauge-pool_non_paged_peak interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PoolNonpagedPeak)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/server/gauge-pool_paged_peak interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.PoolPagedFailures)"
  }

  # Collecting number of Transact-SQL command batches received per second and number of SQL compilations per second
  # see: https://msdn.microsoft.com/en-us/library/ms190911.aspx
  $res =  Get-WmiObject -Query "select BatchRequestsPersec, SQLCompilationsPersec from Win32_PerfFormattedData_MSSQLSERVER_SQLServerSQLStatistics"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-batch-requests-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.BatchRequestsPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-sql-compilations-per-sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.SQLCompilationsPersec)"
  }

  # Collecting following data from performance counters that monitor more than one instance of a component processor on the computer:
  #  - Rate of switches from one thread to another
  #  - Number of threads in the processor queue.
  # see: https://msdn.microsoft.com/en-us/library/aa394272(v=vs.85).aspx
  $res =  Get-WmiObject -Query "select ContextSwitchesPersec, ProcessorQueueLength from Win32_PerfFormattedData_PerfOS_System"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/system/gauge-context_switches_per_sec interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.ContextSwitchesPersec)"
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/system/gauge-processor_queue_length interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.ProcessorQueueLength)"
  }

  # Collecting number of active threads in SQL server and SQL Writer server(provides added functionality for backup and restore of SQL Server) processes
  # see: https://msdn.microsoft.com/en-us/library/aa394277(v=vs.85).aspx
  $res =  Get-WmiObject -Query "select ThreadCount from Win32_PerfFormattedData_PerfProc_Process where Name='sqlservr'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-threads interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.ThreadCount)"
  }
  $res =  Get-WmiObject -Query "select ThreadCount from Win32_PerfFormattedData_PerfProc_Process where Name='sqlwriter'"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-writer-threads interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.ThreadCount)"
  }

  # Collecting the number of users currently connected to SQL Server
  # see: https://msdn.microsoft.com/en-us/library/ms190697.aspx
  $res =  Get-WmiObject -Query "select UserConnections from Win32_PerfFormattedData_MSSQLSERVER_SQLServerGeneralStatistics"
  if ($res) {
    Write-Host "PUTVAL $Env:COLLECTD_HOSTNAME/sql-server/gauge-user-connections interval=$Env:COLLECTD_INTERVAL ${nowT}:$($res.UserConnections)"
  }

  Sleep $Env:COLLECTD_INTERVAL
}
