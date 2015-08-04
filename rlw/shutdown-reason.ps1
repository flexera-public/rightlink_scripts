# Since the decommision bundle runs before sending a shutdown to windows, we are unable to
# obtain the reason from the OS as to why it will be shut down.  As a result,
# the os_decom_reason variable will be set to 'not_applicable'
#
# We pull the reason RightScale thinks the instance is going down and put it in
# rs_decom_reason. Note that this variable will only be populated if we issue a
# stop/terminate/reboot from either the RightScale dashboard or the API. It will
# be empty if we shutdown or rebooted at the command line, or if a shutdown/reboot
# was issued on the cloud provider's console. Note we can't tell if a terminate
# was issued on a cloud provider's console, as we just know the system is going
# down. rs_decom_reason possible values are:
#   stop = instance is being stopped/shutdown but disk persists
#   terminate = instance is being destroyed/deleted
#   reboot = instance is being rebooted
#
# DECOM_REASON is mimics rs_decom_reason. We export this value as an environment
# parameter so subsequent scripts in the decommission bundle may have use it. The
# following values are possible:
#   stop
#   terminate
#   reboot
#   unknown (default, occurs when shutdown down done outside RightScale)

Write-Output 'Decommissioning. Calculating reason for decommission: '

$os_decom_reason = 'not_applicable'

$RIGHTLINK_DIR = 'C:\Program Files\RightScale\RightLink'
$rs_decom_reason = & "${RIGHTLINK_DIR}\rsc.exe" rl10 show /rll/proc/shutdown_kind

if ($rs_decom_reason) {
  $decom_reason = $rs_decom_reason
} else {
  $decom_reason = 'unknown'
}

Write-Output "  OS decommission reason is: ${os_decom_reason}"
Write-Output "  RightScale decommission reason is: ${rs_decom_reason}"
Write-Output "  Combined DECOM_REASON is ${decom_reason}"
Write-Output ""
Write-Output "exporting DECOM_REASON=$decom_reason into the environment for subsequent scripts"
& "${RIGHTLINK_DIR}\rsc.exe" rl10 update /rll/env/DECOM_REASON payload=${decom_reason}
