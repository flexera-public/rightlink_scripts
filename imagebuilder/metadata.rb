name        "imagebuilder"
maintainer  "RightScale, Inc."
license     "see LICENSE file in repository root"
description "Scripts for the Image Builder ServerTemplate"
version     '1.0.0'

recipe      "imagebuilder::packer_install", "Install Packer"
recipe      "imagebuilder::packer_install_plugins", "Install Necessary Packer Plugins"
recipe      "imagebuilder::packer_configure", "Configure Packer JSON file"
recipe      "imagebuilder::packer_build", "Run Packer build"
recipe      "imagebuilder::azure_install_tools", "Install Azure tools"
recipe      "imagebuilder::azure_copy_blob", "Azure Copy Blob"

attribute   "CLOUD",
  :display_name => "CLOUD",
  :required => "recommended",
  :description => "Select the cloud where you are building the image",
  :type => "string",
  :choice => ["azure","ec2","google","software"],
  :recipes => [
    "imagebuilder::packer_install",
    "imagebuilder::packer_configure",
    "imagebuilder::packer_install_plugins"
  ]

attribute   "AWS_SECRET_KEY",
  :display_name => "The AWS Secret Key",
  :required => "optional",
  :type => "string",
  :description => "The AWS Secret key",
  :default => "cred:AWS_SECRET_KEY",
  :recipes => ["imagebuilder::packer_build"]

  attribute   "AWS_ACCESS_KEY",
    :display_name => "The AWS Access Key",
    :required => "optional",
    :type => "string",
    :description => "The AWS Access key",
    :default => "cred:AWS_ACCESS_KEY",
    :recipes => ["imagebuilder::packer_build"]
