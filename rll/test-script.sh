#! /bin/bash -ex
set -x
echo VAR=$VAR
echo CRED=$CRED
printenv
egrep 's0ozzw8vboglcnc0cpie' test-attachment.txt
