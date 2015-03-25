#! /bin/bash -ex
# This test script is used by the regression tester in RightLink10 to verify that recipes can be
# executed and that credentials are not echoed to the audit entry
set -x
echo VAR=$VAR
echo CRED=$CRED
printenv
egrep 'Hi Mom' "attachments/test-attachment.txt"
