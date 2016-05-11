#! /bin/bash

# ---
# RightScript Name: Azure copy blob
# Description: |
#   Copy Blob
# Inputs: {}
# ...

# Original image name to copy
orig_image=`sudo grep -o "\".*\"" /root/rightimage_id_list | sed 's/"//g'`

function blob_copy_status {
  # Just because the blob exists doesn't mean it's finished yet
  res=`azure storage blob copy show --container "$AZURE_STORAGE_ACCOUNT_CONTAINER_DEST" --account-name "$AZURE_STORAGE_ACCOUNT_DEST" --account-key "$AZURE_STORAGE_ACCESS_KEY_DEST" --blob "${vhd_uri_base}"`
  # Piping azure command through grep causes a broken pipe error.
  [[ $res =~ "success" ]]
}

function blob_list {
  res=`azure storage blob list --container "$AZURE_STORAGE_ACCOUNT_CONTAINER_DEST" --account-name "$AZURE_STORAGE_ACCOUNT_DEST" --prefix "${vhd_uri_base}" --account-key "$AZURE_STORAGE_ACCESS_KEY_DEST"`
  [[ $res =~ ${vhd_uri_base} ]]
}

function wait_for_blob {
  i=0
  while [ $i -lt 60 ]; do
    blob_copy_status && break
    sleep 60
    i=$[$i+1]
  done
}

function show_image {
  azure vm image show "${1}"
}

set -ex

azure account import /tmp/packer/publishsettings
vhd_uri=`show_image ${orig_image} | grep mediaLink | grep -o "\".*\"" | sed 's/"//g'`
vhd_uri_base=`basename ${vhd_uri}`

if blob_list; then
  echo "Blob already exists in destination location"
  wait_for_blob
else
  azure storage blob copy start --source-uri ${vhd_uri} \
    --dest-account-name "$AZURE_STORAGE_ACCOUNT_DEST" \
    --dest-account-key "$AZURE_STORAGE_ACCESS_KEY_DEST" \
    --dest-container "$AZURE_STORAGE_ACCOUNT_CONTAINER_DEST"
  wait_for_blob
fi

if show_image $IMAGE_NAME; then
  echo "Destination image already exists. Skipping registration"
else
  shopt -s nocasematch
  if [[ $IMAGE_NAME =~ Windows ]]; then
    os_type="Windows"
  else
    os_type="Linux"
  fi

  azure vm image create $IMAGE_NAME --os ${os_type} --location "West US" --blob-url https://$AZURE_STORAGE_ACCOUNT_DEST.blob.core.windows.net/$AZURE_STORAGE_ACCOUNT_CONTAINER_DEST/${vhd_uri_base}
  # Rewrite image id list with final image name
  echo "{\"$IMAGE_NAME\": {}}" | sudo tee /root/rightimage_id_list >/dev/null
fi

if [ "${orig_image}" == "$IMAGE_NAME" ]; then
  echo "Protecting against script re-run. Skipping image deletion."
else
  azure vm image delete --blob-delete ${orig_image}
fi
