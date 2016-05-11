#! /bin/bash -e

# ---
# RightScript Name: Packer Configure
# Description: |
#   Create the Packer JSON file.
# Attachments:
#   - azure.json
#   - azure.sh
#   - cleanup.sh
#   - cloudinit.sh
#   - ec2.json
#   - google.json
#   - rightlink.ps1
#   - rightlink.sh
#   - rs-cloudinit.sh
#   - scriptpolicy.ps1
#   - softlayer.json
# Inputs:
#   CLOUD:
#     Input Type: single
#     Category: Cloud
#     Description: |
#      Select the cloud you are launching in
#     Required: true
#     Advanced: false
#     Possible Values:
#       - text:ec2
#       - text:google
#       - text:azure
#       - text:softlayer
#   DATACENTER:
#     Input Type: single
#     Category: Cloud
#     Description: |
#      Enter the Cloud Datacenter or availablity zone where you want to build the image
#     Required: true
#     Advanced: false
#   IMAGE_NAME:
#     Input Type: single
#     Category: Cloud
#     Description: |
#      Enter the name of the new image to be created.
#     Required: true
#     Advanced: false
#   SOURCE_IMAGE:
#     Input Type: single
#     Category: Cloud
#     Description: |
#      Enter the Name or Resource ID of the base image to use.
#     Required: true
#     Advanced: false
#   AZURE_PUBLISHSETTINGS:
#     Input Type: single
#     Category: Azure
#     Description: |
#      The Azure Publishing settings
#     Required: false
#     Advanced: true
#   GOOGLE_ACCOUNT:
#     Input Type: single
#     Category: Google
#     Description: |
#      The Google Service Account JSON file.  This is best placed in a Credential
#     Required: false
#     Advanced: true
#   INSTANCE_TYPE:
#     Input Type: single
#     Category: Cloud
#     Description: |
#      The cloud instance type to use to build the image
#     Required: true
#     Advanced: false
#   GOOGLE_PROJECT:
#     Input Type: single
#     Category: Google
#     Description: |
#      The Google project where to build the image.
#     Required: false
#     Advanced: true
#   GOOGLE_NETWORK:
#     Input Type: single
#     Category: Google
#     Description: |
#       The Google Compute network to use for the launched instance. Defaults to "default".
#     Required: false
#     Advanced: true
#   GOOGLE_SUBNETWORK:
#     Input Type: single
#     Category: Google
#     Description: |
#       The Google Compute subnetwork to use for the launced instance. Only required if the network has been created with custom subnetting. Note, the region of the subnetwork must match the region or zone in which the VM is launched.
#     Required: false
#     Advanced: true
#   RIGHTLINK_VERSION:
#     Input Type: single
#     Category: RightLink
#     Description: |
#       RightLink version number or branch name to install.  Leave blank to NOT bundle RightLink in the image
#     Required: false
#     Advanced: true
#   AZURE_STORAGE_ACCOUNT:
#     Input Type: single
#     Category: Azure
#     Description: |
#      Azure storage account used for images
#     Required: false
#     Advanced: true
#   AZURE_STORAGE_ACCOUNT_CONTAINER:
#     Input Type: single
#     Category: Azure
#     Description: |
#      Azure storage account container used for images
#     Required: false
#     Advanced: true
#   SSH_USERNAME:
#     Input Type: single
#     Category: Misc
#     Description: |
#      The user packer will use to SSH into the instance.  Examples: ubuntu, centos, ec2-user, root
#     Required: true
#     Advanced: true
#   AWS_SUBNET_ID:
#     Input Type: single
#     Category: AWS
#     Description: |
#      The vpc subnet resource id to build image in.Enter a value if use a AWS VPC vs EC2-Classic
#     Required: false
#     Advanced: true
#   AWS_VPC_ID:
#     Input Type: single
#     Category: AWS
#     Description: |
#      The vpc resource id to build image in.  Enter a value if use a AWS VPC vs EC2-Classic
#     Required: false
#     Advanced: true
#   IMAGE_PASSWORD:
#     Input Type: single
#     Category: Misc
#     Description: |
#      Enter  a password on the image
#     Required: false
#     Advanced: true
# ...

PACKER_DIR=/tmp/packer
PACKER_CONF=${PACKER_DIR}/packer.json

echo "Copying cloud config"
cp ${RS_ATTACH_DIR}/${CLOUD}.json ${PACKER_CONF}

# Common variables
echo "Configuring common variables"
sed -i "s#%%DATACENTER%%#$DATACENTER#g" ${PACKER_CONF}
sed -i "s#%%INSTANCE_TYPE%%#$INSTANCE_TYPE#g" ${PACKER_CONF}
sed -i "s#%%SSH_USERNAME%%#$SSH_USERNAME#g" ${PACKER_CONF}
sed -i "s#%%IMAGE_NAME%%#$IMAGE_NAME#g" ${PACKER_CONF}
sed -i "s#%%RIGHTLINK_VERSION%%#$RIGHTLINK_VERSION#g" rightlink.*

# Copy config files
echo "Copying scripts"
for file in *.sh *.ps1; do
  cp ${RS_ATTACH_DIR}/${file} ${PACKER_DIR}
done

# Cloud-specific configuration
echo "Cloud-specific configuration"
case "$CLOUD" in
"azure")
  account_file=${PACKER_DIR}/publishsettings
  echo "$AZURE_PUBLISHSETTINGS" > $account_file

  if [[ $IMAGE_NAME =~ Windows ]]; then
    os_type="Windows"
    provisioner='"type": "azure-custom-script-extension", "script_path": "rightlink.ps1"'
  else
    os_type="Linux"
    provisioner='"type": "shell", "scripts": [ "cloudinit.sh", "rightlink.sh", "azure.sh", "cleanup.sh" ]'
  fi
  sed -i "s#%%OS_TYPE%%#$os_type#g" ${PACKER_CONF}

  sed -i "s#%%ACCOUNT_FILE%%#$account_file#g" ${PACKER_CONF}
  sed -i "s#%%PROVISIONER%%#$provisioner#g" ${PACKER_CONF}
  sed -i "s#%%STORAGE_ACCOUNT%%#$AZURE_STORAGE_ACCOUNT#g" ${PACKER_CONF}
  sed -i "s#%%STORAGE_ACCOUNT_CONTAINER%%#$AZURE_STORAGE_ACCOUNT_CONTAINER#g" ${PACKER_CONF}

  # Azure plugin requires this directory
  home=${HOME}
  user=${USER}
  dir=$home/.packer_azure
  sudo mkdir -p $dir && sudo chown $user $dir
  ;;
"ec2")
  sed -i "s#%%BUILDER_TYPE%%#amazon-ebs#g" ${PACKER_CONF}

  if [ ! -z "$AWS_VPC_ID" ]; then
    sed -i "s#%%VPC_ID%%#$AWS_VPC_ID#g" ${PACKER_CONF}
  else
    sed -i "/%%VPC_ID%%/d" ${PACKER_CONF}
  fi

  if [ ! -z "$AWS_SUBNET_ID" ]; then
    sed -i "s#%%SUBNET_ID%%#$AWS_SUBNET_ID#g" ${PACKER_CONF}
  else
    sed -i "/%%SUBNET_ID%%/d" ${PACKER_CONF}
  fi

  ;;
"google")
  if [[ $IMAGE_NAME =~ windows ]]; then
    communicator="winrm"
    disk_size="50"
    provisioner='"type": "powershell", "scripts": ["rightlink.ps1","scriptpolicy.ps1"]'
  else
    communicator="ssh"
    disk_size="10"
    provisioner='"type": "shell", "scripts": [ "cloudinit.sh", "rightlink.sh", "cleanup.sh" ]'
  fi
  sed -i "s#%%DISK_SIZE%%#$disk_size#g" ${PACKER_CONF}

  account_file=${PACKER_DIR}/account.json
  echo "$GOOGLE_ACCOUNT" > $account_file

  sed -i "s#%%ACCOUNT_FILE%%#$account_file#g" ${PACKER_CONF}
  sed -i "s#%%PROJECT%%#$GOOGLE_PROJECT#g" ${PACKER_CONF}
  sed -i "s#%%COMMUNICATOR%%#$communicator#g" ${PACKER_CONF}
  sed -i "s#%%PROVISIONER%%#$provisioner#g" ${PACKER_CONF}
  sed -i "s#%%IMAGE_PASSWORD%%#$IMAGE_PASSWORD#g" ${PACKER_CONF}
  sed -i "s#%%GOOGLE_NETWORK%%#$GOOGLE_NETWORK#g" ${PACKER_CONF}
  sed -i "s#%%GOOGLE_SUBNETWORK%%#$GOOGLE_SUBNETWORK#g" ${PACKER_CONF}

  SOURCE_IMAGE=`echo $SOURCE_IMAGE | rev | cut -d'/' -f1 | rev`
  ;;
esac

sed -i "s#%%SOURCE_IMAGE%%#$SOURCE_IMAGE#g" ${PACKER_CONF}
