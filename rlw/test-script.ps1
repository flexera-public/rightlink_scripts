# This file begins with a UTF-8 byte order mark (BOM).

# This test script is used by the regression tester in RightLink10 and
# rightlink tester for smoke testing to verify that recipe can be
# executed and that credentials are not echoed to the audit entry

$RUN_AS = 'recipe:'

Write-Output "${RUN_AS} STRING_INPUT_1: $env:STRING_INPUT_1"
Write-Output "${RUN_AS} STRING_INPUT_2: $env:STRING_INPUT_2"
Write-Output "${RUN_AS} UTF8_STRING_INPUT: $env:UTF8_STRING_INPUT"
Write-Output "${RUN_AS} ARRAY_INPUT_1: $env:ARRAY_INPUT_1"
# Send to audit entry
Write-Output "${RUN_AS} CRED_INPUT: $env:CRED_INPUT"
# Send to file to be checked by tests, Windows filenames can't have colons, so it is replaced with a -
$runType = $RUN_AS -replace ':', '-'
[System.IO.File]::WriteAllText("C:\Windows\Temp\${runType}cred.txt", "${RUN_AS} CRED_INPUT: $env:CRED_INPUT\n")
# Check that UTF-8 chars are kept in RightScript/Recipe
Write-Output "${RUN_AS} UTF8_CHAR: ☃"

Get-ChildItem Env:
Get-Content "${PSScriptRoot}\attachments\test-attachment.txt" | Select-String 's0ozzw8vboglcnc0cpie' | % { $_ -Replace 'Random string: ', '' }

& 'C:\Program Files\RightScale\RightLink\rsc.exe' --rl10 cm15 multi_add /api/tags/multi_add resource_hrefs[]=$env:RS_SELF_HREF tags[]=recipe:tag=true
