name        "rightlink"
maintainer  "RightScale, Inc."
license     "see LICENSE file in repository root"
description "Base scripts for RightLink10 (RLL) to initialize basic functionality"
version     "10.0.3"

recipe      "rightlink::wait-for-eip", "Wait for external IP address to be assigned (EC2 issue)"
recipe      "rightlink::setup_software_repo", "Initializes repositories"
recipe      "rightlink::setup_hostname", "Changes the hostname of the server"
recipe      "rightlink::collectd", "Installs and configures collectd for RightScale monitoring"
recipe      "rightlink::upgrade", "Check whether a RightLink upgrade is available and do the upgrade"
recipe      "rightlink::shutdown-reason", "Print out the reason for shutdown"
recipe      "rightlink::setup_automatic_upgrade", "Periodically checks if an upgrade is available and upgrade if there is."

attribute   "SERVER_HOSTNAME",
  :display_name => "Hostname for this server",
  :description => "The server's hostname is set to the longest valid prefix or suffix of " +
	"this variable. E.g. 'my.example.com V2', 'NEW my.example.com', and " +
	"'database.io my.example.com' all set the hostname to 'my.example.com'. " +
	"Set to an empty string to avoid any change to the hostname.",
  :required => "optional",
  :type => "string",
  :default => "env:RS_SERVER_NAME",
  :recipes => ["rightlink::setup_hostname"]

attribute   "COLLECTD_SERVER",
  :display_name => "RightScale monitoring server to send data to",
  :required => "optional",
  :type => "string",
  :default => "env:RS_SKETCHY",
  :recipes => ["rightlink::collectd"]

attribute   "RS_INSTANCE_UUID",
  :display_name => "RightScale monitoring ID for this server",
  :required => "optional",
  :type => "string",
  :default => "env:RS_INSTANCE_UUID",
  :recipes => ["rightlink::collectd"]

attribute   "ENABLE_AUTO_UPGRADE",
  :display_name => "Enables auto upgrade of RightLink10",
  :required => "optional",
  :type => "string",
  :default => "true",
  :choice => ["true", "false"],
  :recipes => ["rightlink::setup_automatic_upgrade"]

attribute   "UPGRADES_FILE_LOCATION",
  :display_name => "External location of 'upgrades' file",
  :required => "optional",
  :type => "string",
  :default => "https://rightlinklite.rightscale.com/rll/upgrades",
  :recipes => ["rightlink::upgrade"]
