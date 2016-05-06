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
  :description => "Select the cloud you are launching in",
  :type => "string",
  :default => "env:RS_ISLAND",
  :recipes => [
    "imagebuilder::packer_install",
    "imagebuilder::packer_configure",
    "imagebuilder::packer_install_plugins"
  ]

attribute   "FREEZE_DATE",
  :display_name => "OS repository freeze date",
  :required => "recommended",
  :type => "string",
  :description => "Day from which to set RightScale-hosted OS repository mirror. Can be an empty string to disable this feature, 'latest' to always pull today's mirrors, or a day in format YYYY-MM-DD to pull from a particular day",
  :default => "",
  :recipes => ["rll-examples::rightscale-mirrors"]

attribute   "RUBYGEMS_FREEZE_DATE",
  :display_name => "Rubygems freeze date",
  :required => "recommended",
  :type => "string",
  :description => "Day from which to set RightScale-hosted Rubygems mirror. Can be an empty string to disable this feature, 'latest' to always pull today's mirrors, or a day in format YYYY-MM-DD to pull from a particular day",
  :default => "",
  :recipes => ["rll-examples::rightscale-mirrors"]
