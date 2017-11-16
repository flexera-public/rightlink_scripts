# ---
# RightScript Name: RL10 Windows Setup Alerts
# Description: |
#   Set up the RightScale Alerts on the instance to match the metrics that it is actually reporting with the built-in
#   RightLink monitoring. The RightScale Alerts on this ServerTemplate are set to match the metrics reported by the
#   built-in RightLink monitoring, but there are a few metrics which have names which vary based on the system they are
#   running.
#
#   The alerts that need to be set up by this script are:
#
#   * **rs high network tx activity** and **rs high network rx activity**: On Windows the network interface name comes
#     from the name of the emulated or virtualized network interface driver which differs between hypervisors and clouds
#     and there may be more network interfaces on the system, so this script will update and add the alerts to match the
#     network interfaces on the system.
# Inputs: {}
# Attachments: []
# ...

$ErrorActionPreference = 'Stop'

# Create an alert spec on the instance based on a template alert spec from the ServerTemplate with optional parameter
# overrides.
#
# [string]$templateName: the alert spec template name
# [string]$instanceName: the instance name to append to the template name which is used to name the new alert spec
# [hashtable]$overrides: the parameter names and values to override for the new alert spec
#
function Create-AlertSpec([string]$templateName, [string]$instanceName, [hashtable]$overrides = @{}) {
  $RIGHTLINK_DIR = "$env:ProgramFiles\RightScale\RightLink"
  $name = "$templateName $instanceName"
  [System.Console]::Write("creating alert spec '$name' from '$templateName': ")
  if ($overrides.Count) {
    [System.Console]::Write('overriding ')
    $overrides.Keys | ForEach-Object { [System.Console]::Write("$_='" + $overrides[$_] + "' ") }
  }
  [System.Console]::Write("... ")

  # check in the alert specs to see if the one we want to create is already created
  try {
    $alertSpecs | & "${RIGHTLINK_DIR}\rsc.exe" json --x1 "object:has(.name:val(\`"$name`\`")) " 2>&1>$null
  } catch {}
  if ($LASTEXITCODE -eq 0) {
    Write-Output 'already exists'
    return
  }

  # create a hashtable of the parameters by cloning the overrides and setting the name parameter and and all of other
  # non-overridden parameters from the alert spec
  $parameters = [Hashtable]$overrides.Clone()
  $parameters.Add('name', $name)
  @('condition'; 'description'; 'duration'; 'escalation_name'; 'file'; 'threshold'; 'variable'; 'vote_tag'; 'vote_type') | ForEach-Object {
    $parameter = $_
    if (!$parameters.Contains($parameter)) {
      try {
        $value = $alertSpecs | & "${RIGHTLINK_DIR}\rsc.exe" json --x1 "object:has(.name:val(\`"$templateName\`")).$parameter " 2>$null
        if ($value) {
          $parameters.Add($parameter, $value)
        }
      } catch {}
    }
  }

  # transform the hashtable of parameters into an array of arguments for rsc
  $arguments = New-Object System.Collections.ArrayList
  $parameters.Keys | ForEach-Object {
    $parameter = $_
    $arguments.Add("alert_spec[$parameter]=" + $parameters[$parameter]) | Out-Null
  }

  # use rsc to create the new alert spec with the parameters as arguments
  & "${RIGHTLINK_DIR}\rsc.exe" --rl10 cm15 create "$env:RS_SELF_HREF/alert_specs" $arguments
  if ($LASTEXITCODE) { Exit $LASTEXITCODE }
  Write-Output 'created'
}

# Destroy an alert if the matching alert spec is defined on the ServerTemplate or destroy an alert spec if it is defined
# on the instance. No action will be taken if the alert or alert spec has already been destroyed or does not otherwise
# exist.
#
# [string]$name: the name of the alert spec to destroy the alert for or to just destroy
#
function Destroy-AlertOrAlertSpec([string]$name) {
  $RIGHTLINK_DIR = "$env:ProgramFiles\RightScale\RightLink"
  [System.Console]::Write("destroying alert or alert spec '$name' from instance: ... ")

  # check if the alert or alert spec has already been destroyed
  if ((Exists-AlertForAlertSpec $name) -eq $false) {
    Write-Output 'already destroyed'
    return
  }

  # destroy the alert if the alert spec is inherited from the ServerTemplate or delete the alert spec otherwise
  if ($subjectHref -match '/api/server_templates/[^/]+$') {
    $alertHref = $alerts | & "${RIGHTLINK_DIR}\rsc.exe" json --xj "object:has(.href:val(\`"$alertSpecHref\`")) ~ object" | rsc json --x1 'object:has(.rel:val(\"self\")).href'
    & "${RIGHTLINK_DIR}\rsc.exe" --rl10 cm15 destroy $alertHref
  } else {
    & "${RIGHTLINK_DIR}\rsc.exe" --rl10 cm15 destroy $alertSpecHref
  }
  if ($LASTEXITCODE) { Exit $LASTEXITCODE }

  Write-Output 'destroyed'
}

# Check if an alert for an alert spec exists on the instance.
#
# [string]$name: the name of the alert spec to check for
#
# Output variables:
#
# $alertSpecHref: the HREF of the named alert spec
# $subjectHref:   the HREF of the subject of the named alert spec
#
function Exists-AlertForAlertSpec([string]$name) {
  $RIGHTLINK_DIR = "$env:ProgramFiles\RightScale\RightLink"

  # get the alert spec and subject HREFs for the named alert spec
  try {
    $Global:alertSpecHref = $alertSpecs | & "${RIGHTLINK_DIR}\rsc.exe" json --x1 "object:has(.name:val(\`"$name\`")) object:has(.rel:val(\`"self\`")).href" 2>$null
  } catch {}
  try {
    $Global:subjectHref = $alertSpecs | & "${RIGHTLINK_DIR}\rsc.exe" json --x1 "object:has(.name:val(\`"$name\`")) object:has(.rel:val(\`"subject\`")).href" 2>$null
  } catch {}

  # check if the alert spec HREF was found
  if ($alertSpecHref) {
    if ($subjectHref -match '/api/server_templates/[^/]+$') {
      # the subject of the alert spec is a ServerTemplate so the alert spec is inherited
      # check if there is an alert for the alert spec
      try {
        $alerts | & "${RIGHTLINK_DIR}\rsc.exe" json --x1 "object:has(.href:val(\`"$alertSpecHref\`")) " 2>&1>$null
      } catch {}
      if ($LASTEXITCODE -eq 0) {
        # an alert for the alert spec exists
        return $true
      } else {
        # there is no alert for the alert spec
        return $false
      }
    } else {
      # the alert spec is not inherited from the ServerTemplate and it exists so it definitely exists
      return $true
    }
  } else {
    # there was no alert spec HREF found so the named alert spec does not exist
    return $false
  }
}

$RIGHTLINK_DIR = "$env:ProgramFiles\RightScale\RightLink"

# determine which network interfaces exist so we can update alert specs
$interfaces = (Get-WmiObject Win32_PerfRawData_Tcpip_NetworkInterface -Filter 'BytesReceivedPerSec > 10000 AND BytesSentPerSec > 10000').Name -replace '[^0-9A-Za-z]+', '_'

# get all of the alert specs and alerts defined on the instance; these variables are used with rsc json by the above
# functions instead of making individual API calls to query this data
$alertSpecs = & "${RIGHTLINK_DIR}\rsc.exe" --rl10 cm15 index "$env:RS_SELF_HREF/alert_specs" with_inherited=true
if ($LASTEXITCODE) { Exit $LASTEXITCODE }
if (!$alertSpecs) { $alertSpecs = '{}' }
$alerts = & "${RIGHTLINK_DIR}\rsc.exe" --rl10 cm15 index "$env:RS_SELF_HREF/alerts"
if ($LASTEXITCODE) { Exit $LASTEXITCODE }
if (!$alerts) { $alerts = '{}' }

$disableAwsPvNetworkDevice0 = $true # by default remove the original network alert specs
$interfaceFile = 'interface-AWS_PV_Network_Device_0/if_octets' # this is the format for the network metric

$interfaces | ForEach-Object {
  $interface = $_

  # if the interface is AWS_PV_Network_Device_0, do not create a new alert spec
  if ($interface -eq 'AWS_PV_Network_Device_0') {
    $disableAwsPvNetworkDevice0 = $false # since the AWS_PV_Network_Device_0 interface exists do not remove the original alerts
    Write-Output "keeping 'rs high network tx activity'" "keeping 'rs high network rx activity'"
    continue
  }

  # add network alert specs for this network interface by replacing eth0 in the network metric format with the actual
  # interface name
  Create-AlertSpec 'rs high network tx activity' $interface @{file = $interfaceFile.Replace('AWS_PV_Network_Device_0', $interface)}
  Create-AlertSpec 'rs high network rx activity' $interface @{file = $interfaceFile.Replace('AWS_PV_Network_Device_0', $interface)}
}

# if there is no AWS_PV_Network_Device_0 interface, remove the original alerts
if ($disableAwsPvNetworkDevice0 -eq $true) {
  Destroy-AlertOrAlertSpec 'rs high network tx activity'
  Destroy-AlertOrAlertSpec 'rs high network rx activity'
}
