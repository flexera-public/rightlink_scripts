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
#   * *rs high network tx activity* and *rs high network rx activity*: On Windows the network interface name comes from
#     the name of the emulated or virtualized network interface driver which differs between hypervisors and clouds and
#     there may be more network interfaces on the system, so this script will update and add the alerts to match the
#     network interfaces on the system.
# Inputs: {}
# Attachments: []
# ...

$ErrorActionPreference = 'Stop'

function Create-AlertSpec([string]$templateName, [string]$instanceName, [hashtable]$override = @{}) {
    $name = "$templateName $instanceName"
    [System.Console]::Write("creating alert spec '$name' from '$templateName': ")
    if ($override.Count) {
        [System.Console]::Write('overriding ')
        $override.Keys | ForEach-Object { [System.Console]::Write("$_='" + $override[$_] + "' ") }
    }
    [System.Console]::Write("... ")

    try {
        $alertSpecs | rsc json --x1 "object:has(.name:val(\`"$name`\`")) " 2>&1>$null
    } catch {}
    if ($LASTEXITCODE -eq 0) {
        Write-Output 'already exists'
        return
    }

    $parameters = [Hashtable]$override.Clone()
    $parameters.Add('name', $name)
    @('condition'; 'description'; 'duration'; 'escalation_name'; 'file'; 'threshold'; 'variable'; 'vote_tag'; 'vote_type') | ForEach-Object {
        $parameter = $_
        if (!$parameters.Contains($parameter)) {
            try {
                $value = $alertSpecs | rsc json --x1 "object:has(.name:val(\`"$templateName\`")).$parameter " 2>$null
                if ($value) {
                    $parameters.Add($parameter, $value)
                }
            } catch {}
        }
    }

    $arguments = New-Object System.Collections.ArrayList
    $parameters.Keys | ForEach-Object {
        $parameter = $_
        $arguments.Add("alert_spec[$parameter]=" + $parameters[$parameter]) | Out-Null
    }

    rsc --rl10 cm15 create "$env:RS_SELF_HREF/alert_specs" $arguments
    if ($LASTEXITCODE) { Exit $LASTEXITCODE }

    Write-Output 'created'
}

function Destroy-AlertOrAlertSpec([string]$name) {
    [System.Console]::Write("destroying alert or alert spec '$name' from instance: ... ")

    if ((Exists-AlertForAlertSpec $name) -eq $false) {
        Write-Output 'already destroyed'
        return
    }

    if ($subjectHref -match '/api/server_templates/[^/]+$') {
        $alertHref = $alerts | rsc json --xj "object:has(.href:val(\`"$alertSpecHref\`")) ~ object" | rsc json --x1 'object:has(.rel:val(\"self\")).href'
        rsc --rl10 cm15 destroy $alertHref
    } else {
        rsc --rl10 cm15 destroy $alertSpecHref
    }
    if ($LASTEXITCODE) { Exit $LASTEXITCODE }

    Write-Output 'destroyed'
}

function Exists-AlertForAlertSpec([string]$name) {
    try {
        $Global:alertSpecHref = $alertSpecs | rsc json --x1 "object:has(.name:val(\`"$name\`")) object:has(.rel:val(\`"self\`")).href" 2>$null
    } catch {}
    try {
        $Global:subjectHref = $alertSpecs | rsc json --x1 "object:has(.name:val(\`"$name\`")) object:has(.rel:val(\`"subject\`")).href" 2>$null
    } catch {}

    if ($alertSpecHref) {
        if ($subjectHref -match '/api/server_templates/[^/]+$') {
            try {
                $alerts | rsc json --x1 "object:has(.href:val(\`"$alertSpecHref\`")) " 2>&1>$null
            } catch {}
            if ($LASTEXITCODE -eq 0) {
                return $true
            } else {
                return $false
            }
        } else {
            return $true
        }
    } else {
        return $false
    }
}

$interfaces = (Get-WmiObject Win32_PerfRawData_Tcpip_NetworkInterface -Filter 'BytesReceivedPerSec > 10000 AND BytesSentPerSec > 10000').Name -replace '[^0-9A-Za-z]+', '_'

$alertSpecs = rsc --rl10 cm15 index "$env:RS_SELF_HREF/alert_specs" with_inherited=true
if ($LASTEXITCODE) { Exit $LASTEXITCODE }
$alerts = rsc --rl10 cm15 index "$env:RS_SELF_HREF/alerts"
if ($LASTEXITCODE) { Exit $LASTEXITCODE }

$disableAwsPvNetworkDevice0 = $true
$interfaceFile = 'interface-AWS_PV_Network_Device_0/if_octets'

$interfaces | ForEach-Object {
  $interface = $_
  if ($interface -eq 'AWS_PV_Network_Device_0') {
    $disableAwsPvNetworkDevice0 = $false
    Write-Output "keeping 'rs high network tx activity'" "keeping 'rs high network rx activity'"
    continue
  }

  Create-AlertSpec 'rs high network tx activity' $interface @{file = $interfaceFile.Replace('AWS_PV_Network_Device_0', $interface)}
  Create-AlertSpec 'rs high network rx activity' $interface @{file = $interfaceFile.Replace('AWS_PV_Network_Device_0', $interface)}
}

if ($disableAwsPvNetworkDevice0 -eq $true) {
  Destroy-AlertOrAlertSpec 'rs high network tx activity'
  Destroy-AlertOrAlertSpec 'rs high network rx activity'
}
