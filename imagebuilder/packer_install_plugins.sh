#! /bin/bash -ex

# ---
# RightScript Name: Packer Install Plugins
# Description: |
#   Install Packer Plugins
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
# ...

GO_VERSION="1.4"
PACKER_DIR=/tmp/packer

sudo mkdir -p /usr/local
wget --no-verbose https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz

cat <<-EOF > /tmp/etc-profile.d-go.sh
export GOPATH=/tmp/go
export PATH=\$PATH:/usr/local/go/bin:\${GOPATH}/bin
EOF
sudo install -m 0755 /tmp/etc-profile.d-go.sh /etc/profile.d/go.sh
set +x
source /etc/profile
set -x
mkdir -p ${GOPATH}

sudo apt-get -y update
which git || sudo apt-get -y install git-core
sudo apt-get -y install make mercurial-common

case "$CLOUD" in
azure)
  cd ${PACKER_DIR}
  #wget --no-verbose https://github.com/Azure/packer-azure/releases/download/prerelease/packer-azure-linux-amd64-prerelease.tar.gz
  wget --no-verbose https://github.com/lopaka/scratch/raw/master/packer-azure-linux-amd64-rightscale.tar.gz
  tar zxf packer-azure*.tar.gz
  ;;
softlayer)
  test -d ${GOPATH}/src/github.com/mitchellh/packer || git clone https://github.com/mitchellh/packer.git ${GOPATH}/src/github.com/mitchellh/packer
  cd ${GOPATH}/src/github.com/mitchellh/packer
  git checkout f2698b59816f89d9a6798ef85f4f45857fc45a57
  make updatedeps
  make
  make dev
  cp -R ${GOPATH}/src/github.com/mitchellh/packer/bin/* /tmp/packer

  test -d ${GOPATH}/src/github.com/leonidlm/packer-builder-softlayer || git clone https://github.com/leonidlm/packer-builder-softlayer.git ${GOPATH}/src/github.com/leonidlm/packer-builder-softlayer
  cd ${GOPATH}/src/github.com/leonidlm/packer-builder-softlayer
  git checkout aaee0561423ff696e3f516895a9ef671b6d2afd6
  sed -i 's#code.google.com/p/gosshold/ssh#golang.org/x/crypto/ssh#' builder/softlayer/step_create_ssh_key.go
  go build -o ${PACKER_DIR}/packer-builder-softlayer main.go
  ;;
esac
