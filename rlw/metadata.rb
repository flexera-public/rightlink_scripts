name        "rlw"
maintainer  "RightScale, Inc."
license     "see LICENSE file in repository root"
description "Base scripts for RightLink10 on Windows (RLW) to initialize basic functionality"
version     '10.1.5'

recipe      "rlw::setup-automatic-upgrade", "Periodically checks if an upgrade is available and upgrade if there is."
recipe      "rlw::shutdown-reason", "Print out the reason for shutdown"
recipe      "rlw::upgrade", "Check whether a RightLink upgrade is available and do the upgrade"
recipe      "rlw::wait-for-eip", "Wait for external IP address to be assigned (EC2 issue)"

attribute   "ENABLE_AUTO_UPGRADE",
  :display_name => "Enables auto upgrade of RightLink10",
  :required => "optional",
  :type => "string",
  :default => "true",
  :choice => ["true", "false"],
  :recipes => ["rlw::setup-automatic-upgrade"]

attribute   "UPGRADES_FILE_LOCATION",
  :display_name => "External location of 'upgrades' file",
  :required => "optional",
  :type => "string",
  :default => "https://rightlink.rightscale.com/rightlink/upgrades",
  :recipes => ["rlw::upgrade"]
