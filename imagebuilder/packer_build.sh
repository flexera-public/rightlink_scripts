#! /bin/bash -ex

# ---
# RightScript Name: Packer Build
# Description: |
#   Use Packer to build the image
# Inputs:
#   AWS_SECRET_KEY:
#     Input Type: single
#     Category: AWS
#     Description: |
#       AWS Secret Key
#     Required: false
#     Advanced: true
#     Default: cred:AWS_SECRET_KEY
#   AWS_ACCESS_KEY:
#     Input Type: single
#     Category: AWS
#     Description: |
#       AWS Access Key
#     Required: false
#     Advanced: true
#     Default: cred:AWS_ACCESS_KEY
#   GOOGLE_PROJECT:
#     Input Type: single
#     Category: Google
#     Description: |
#       The name of the Google project your Rightscale account is connected to.
#     Required: false
#     Advanced: true
#   SOFTLAYER_API_KEY:
#     Input Type: single
#     Category: Softlayer
#     Description: |
#       The credential for the SOFTLAYER_API_KEY for your cloud account rightscale is using
#     Required: false
#     Advanced: true
#     Default: cred:SOFTLAYER_API_KEY
#   SOFTLAYER_USER_NAME:
#     Input Type: single
#     Category: Softlayer
#     Description: |
#       The credential for the SOFTLAYER_USER_NAME for your cloud account rightscale is using
#     Required: false
#     Advanced: true
#     Default: cred:SOFTLAYER_USER_NAME
# ...

PACKER_DIR=/tmp/packer

cd ${PACKER_DIR}
./packer version
./packer validate packer.json
./packer build -machine-readable packer.json | tee build.log
image_id=`grep --binary-files=text 'artifact,0,id' build.log | cut -d, -f6 | cut -d: -f2`
echo $image_id

test -z "$image_id" && echo "Build failed. See build log at ${PACKER_DIR}/build.log " && exit 1

cloud=`grep --binary-files=text 'artifact,0,builder-id' build.log | cut -d, -f6 | cut -d: -f2 | cut -d. -f2-`
case "$cloud" in
"googlecompute")
  image_id="projects/$GOOGLE_PROJECT/images/$image_id"
  ;;
"softlayer")
  image_id=`grep --binary-files=text 'artifact,0,string' build.log | cut -d, -f6 | grep -o -E "\(.*" | sed 's/(//' | sed 's/)//'`
  ;;
esac

echo "{\"$image_id\": {}}" | sudo tee /root/rightimage_id_list >/dev/null
