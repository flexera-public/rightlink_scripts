#! /bin/bash -ex
set -x
echo VAR=$VAR
echo CRED=$CRED
printenv
egrep 'Hi Mom' test-attachment.txt
