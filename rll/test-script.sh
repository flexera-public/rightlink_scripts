#! /bin/bash -ex
# This test script is used by the regression tester in RightLink10 to verify that recipes can be
# executed and that credentials are not echoed to the audit entry
echo VAR=$VAR
echo CRED=$CRED
printenv
egrep 's0ozzw8vboglcnc0cpie' "attachments/test-attachment.txt"
