name        "rll"
maintainer  "RightScale, Inc."
license     "see LICENSE file in repository root"
description "Base scripts for RightLink10 on Linux (RLL) to initialize basic functionality"
version     '0.2015.3797357231'

recipe      "rll::wait-for-eip", "Wait for external IP address to be assigned (EC2 issue)"
recipe      "rll::security_updates", "Installs security updates"
recipe      "rll::setup_hostname", "Changes the hostname of the server"
recipe      "rll::collectd", "Installs and configures collectd for RightScale monitoring"
recipe      "rll::upgrade", "Check whether a RightLink upgrade is available and do the upgrade"
recipe      "rll::shutdown-reason", "Print out the reason for shutdown"
recipe      "rll::setup_automatic_upgrade", "Periodically checks if an upgrade is available and upgrade if there is."
recipe      "rll::test-script", "Test operational script, used by righlinklite/tester"

attribute   "SERVER_HOSTNAME",
  :display_name => "Hostname for this server",
  :description => "The server's hostname is set to the longest valid prefix or suffix of " +
	"this variable. E.g. 'my.example.com V2', 'NEW my.example.com', and " +
	"'database.io my.example.com' all set the hostname to 'my.example.com'. " +
	"Set to an empty string to avoid any change to the hostname.",
  :required => "optional",
  :type => "string",
  :default => "env:RS_SERVER_NAME",
  :recipes => ["rll::setup_hostname"]

attribute   "COLLECTD_SERVER",
  :display_name => "RightScale monitoring server to send data to",
  :required => "optional",
  :type => "string",
  :default => "env:RS_SKETCHY",
  :recipes => ["rll::collectd"]

attribute   "RS_INSTANCE_UUID",
  :display_name => "RightScale monitoring ID for this server",
  :required => "optional",
  :type => "string",
  :default => "env:RS_INSTANCE_UUID",
  :recipes => ["rll::collectd"]

attribute   "ENABLE_AUTO_UPGRADE",
  :display_name => "Enables auto upgrade of RightLink10",
  :required => "optional",
  :type => "string",
  :default => "true",
  :choice => ["true", "false"],
  :recipes => ["rll::setup_automatic_upgrade"]

attribute   "UPGRADES_FILE_LOCATION",
  :display_name => "External location of 'upgrades' file",
  :required => "optional",
  :type => "string",
  :default => "https://rightlink.rightscale.com/rightlink/upgrades",
  :recipes => ["rll::upgrade"]

attribute   "UTF8_STRING_INPUT",
  :display_name => "UTF8 String Input",
  :required => "recommended",
  :type => "string",
  :default => "hello,здравствуйте",
  :recipes => ["rll::test-script"]

attribute   "STRING_INPUT_1",
  :display_name => "String Input 1",
  :required => "recommended",
  :type => "string",
  :default => "Default String Input 1",
  :recipes => ["rll::test-script"]

attribute   "STRING_INPUT_2",
  :display_name => "String Input 2",
  :required => "recommended",
  :type => "string",
  :default => "Default String Input 2",
  :recipes => ["rll::test-script"]

attribute   "CRED_INPUT",
  :display_name => "Credential Input",
  :required => "recommended",
  :type => "string",
  :recipes => ["rll::test-script"]

attribute   "ARRAY_INPUT_1",
  :display_name => "Array Input 1",
  :required => "recommended",
  :type => "array",
  :default => ["ARRAY_ITEM_1", "ARRAY_ITEM_2", "ARRAY_ITEM_3"],
  :recipes => ["rll::test-script"]
