#! /bin/bash -ex
# This test script is used by the regression tester in RightLink10 and
# rightlink tester for smoke testing to verify that recipe can be
# executed and that credentials are not echoed to the audit entry

run_as='recipe:'

echo "${run_as} STRING_INPUT_1: $STRING_INPUT_1"
echo "${run_as} STRING_INPUT_2: $STRING_INPUT_2"
echo "${run_as} UTF8_STRING_INPUT: $UTF8_STRING_INPUT"
echo "${run_as} ARRAY_INPUT_1: $ARRAY_INPUT_1"
# Send to audit entry
echo "${run_as} CRED_INPUT: $CRED_INPUT"
# Send to file to be checked by tests
echo "${run_as} CRED_INPUT: $CRED_INPUT" > /tmp/${run_as}cred
# Check that UTF-8 chars are kept in RightScript/Recipe
echo "${run_as} UTF8_CHAR: ☃"

printenv
egrep 's0ozzw8vboglcnc0cpie' "attachments/test-attachment.txt"

/usr/local/bin/rsc --rl10 cm15 multi_add /api/tags/multi_add resource_hrefs[]=$RS_SELF_HREF tags[]=recipe:tag=true
