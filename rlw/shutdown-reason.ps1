# ---
# RightScript Name: RL10 Windows Shutdown Reason
# Description: Print out the reason for shutdown.
# Inputs: {}
# ...
#

# The decommission bundle on Windows is only executed if a stop/terminate/reboot
# action is initiated via RightScale dashboard or using the RightScale API.
# On Windows, if a stop/shutdown/reboot action is initiated from the instance or
# the cloud provider's console, the decommission bundle is not executed.
#
# The decommission bundle runs before sending a shutdown to windows.  Because of this,
# we are unable to obtain the reason from the OS as to why it is being shutdown.
#
# We pull the reason RightScale thinks the instance is going down and put it in
# rs_decom_reason. rs_decom_reason possible values are:
#   stop = instance is being stopped/shutdown but disk persists
#   terminate = instance is being destroyed/deleted
#   reboot = instance is being rebooted
#
# DECOM_REASON mimics rs_decom_reason. We export this value as an environment
# parameter so subsequent scripts in the decommission bundle may use it.

Write-Output 'Decommissioning. Calculating reason for decommission: '

$RIGHTLINK_DIR = "$env:ProgramFiles\RightScale\RightLink"

$rs_decom_reason = & "${RIGHTLINK_DIR}\rsc.exe" --retry=5 --timeout=10 rl10 show /rll/proc/shutdown_kind
$decom_reason = $rs_decom_reason

Write-Output "  RightScale decommission reason is: ${rs_decom_reason}"
Write-Output "  Combined DECOM_REASON is: ${decom_reason}"
Write-Output ""
Write-Output "exporting DECOM_REASON=$decom_reason into the environment for subsequent scripts"
& "${RIGHTLINK_DIR}\rsc.exe" rl10 --retry=5 --timeout=10 update /rll/env/DECOM_REASON payload=${decom_reason}
