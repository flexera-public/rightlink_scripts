name        "rlw"
maintainer  "RightScale, Inc."
license     "see LICENSE file in repository root"
description "Base scripts for RightLink10 on Windows (RLL) to initialize basic functionality"
version     '10.1.2'

recipe      "rlw::wait-for-eip", "Wait for external IP address to be assigned (EC2 issue)"
recipe      "rll::security_updates", "Installs security updates"
recipe      "rlw::setup_hostname", "Changes the hostname of the server"
recipe      "rlw::ssc", "Installs and configures SSC for RightScale monitoring"
recipe      "rlw::upgrade", "Check whether a RightLink upgrade is available and do the upgrade"
recipe      "rlw::shutdown-reason", "Print out the reason for shutdown"
recipe      "rlw::setup_automatic_upgrade", "Periodically checks if an upgrade is available and upgrade if there is."
recipe      "rlw::test-script", "Test operational script, used by righlinklite/tester"

attribute   "SERVER_HOSTNAME",
  :display_name => "Hostname for this server",
  :description => "The server's hostname is set to the longest valid prefix or suffix of " +
  "this variable. E.g. 'my.example.com V2', 'NEW my.example.com', and " +
  "'database.io my.example.com' all set the hostname to 'my.example.com'. " +
  "Set to an empty string to avoid any change to the hostname.",
  :required => "optional",
  :type => "string",
  :default => "env:RS_SERVER_NAME",
  :recipes => ["rlw::setup_hostname"]

attribute   "SSC_SERV_VERSION",
  :display_name => "SSC version to use",
  :required => "optional",
  :type => "string",
  :default => "3.5.0",
  :recipes => ["rll::ssc"]

attribute   "SSC_SERV_PLATFORM",
  :display_name => "SSC platform to use",
  :required => "optional",
  :type => "string",
  :default => "x86-64",
  :recipes => ["rll::ssc"]

attribute   "RS_INSTANCE_UUID",
  :display_name => "RightScale monitoring ID for this server",
  :required => "optional",
  :type => "string",
  :default => "env:RS_INSTANCE_UUID",
  :recipes => ["rll::ssc"]

attribute   "ENABLE_AUTO_UPGRADE",
  :display_name => "Enables auto upgrade of RightLink10",
  :required => "optional",
  :type => "string",
  :default => "true",
  :choice => ["true", "false"],
  :recipes => ["rlw::setup_automatic_upgrade"]

attribute   "UPGRADES_FILE_LOCATION",
  :display_name => "External location of 'upgrades' file",
  :required => "optional",
  :type => "string",
  :default => "https://rightlink.rightscale.com/rightlink/upgrades",
  :recipes => ["rlw::upgrade"]

attribute   "TEST_VAR",
  :display_name => "test variable to print for regression tests",
  :required => "recommended",
  :type => "string",
  :default => "test value",
  :recipes => ["rlw::test-script"]

attribute   "TEST_CRED",
  :display_name => "test credential to print for regression tests",
  :required => "recommended",
  :type => "string",
  :default => "cred:AWS_ACCESS_KEY_ID",
  :recipes => ["rlw::test-script"]
