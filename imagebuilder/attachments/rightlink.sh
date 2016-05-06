#!/bin/bash -ex
RIGHTLINK_VERSION="%%RIGHTLINK_VERSION%%"

if [ -z "$RIGHTLINK_VERSION" ]; then
  echo "No RightLink version specified. Skipping RightLink install."
  exit 0
fi

which curl || yum -y install curl || apt-get -y install curl
curl -s https://rightlink.rightscale.com/rll/$RIGHTLINK_VERSION/rightlink.install.sh | sudo bash -s -- -l