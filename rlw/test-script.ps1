# This test script is used by the regression tester in RightLink10 to verify that recipes can be
# executed and that credentials are not echoed to the audit entry
Write-Output "VAR=$env:VAR"
Write-Output "CRED=$env:CRED"
Get-ChildItem Env:
Get-Content "${PSScriptRoot}\attachments\test-attachment.txt" | Select-String 's0ozzw8vboglcnc0cpie' | % { $_ -Replace "Random string: " }
