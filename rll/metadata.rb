name        "rll"
maintainer  "RightScale, Inc."
license     "see LICENSE file in repository root"
description "Base scripts for RightLink10 on Linux (RLL) to initialize basic functionality"
version     '10.2.2'

recipe      "rll::enable-monitoring", "Enables RightLink monitoring or installs collectd for RightScale monitoring"
recipe      "rll::setup-automatic-upgrade", "Periodically checks if an upgrade is available and upgrade if there is."
recipe      "rll::setup-hostname", "Changes the hostname of the server"
recipe      "rll::shutdown-reason", "Print out the reason for shutdown"
recipe      "rll::upgrade", "Check whether a RightLink upgrade is available and do the upgrade"
recipe      "rll::wait-for-eip", "Wait for external IP address to be assigned (EC2 issue)"

attribute   "SERVER_HOSTNAME",
  :display_name => "Hostname for this server",
  :description => "The server's hostname is set to the longest valid prefix or suffix of " +
	"this variable. E.g. 'my.example.com V2', 'NEW my.example.com', and " +
	"'database.io my.example.com' all set the hostname to 'my.example.com'. " +
	"Set to an empty string to avoid any change to the hostname.",
  :required => "optional",
  :type => "string",
  :default => "",
  :recipes => ["rll::setup-hostname"]

attribute   "MONITORING_METHOD",
  :display_name => "Monitoring method to use, either RightLink monitoring or collectd. " +
  "Setting to 'auto' will use code to select method.",
  :required => "optional",
  :type => "string",
  :default => "auto",
  :choice => ["auto", "collectd", "rightlink"],
  :recipes => ["rll::enable-monitoring"]

attribute   "COLLECTD_SERVER",
  :display_name => "If using collectd, the FQDN or IP address of the remote collectd server.",
  :required => "optional",
  :type => "string",
  :default => "env:RS_TSS",
  :recipes => ["rll::enable-monitoring"]

attribute   "RS_INSTANCE_UUID",
  :display_name => "If using collectd, the monitoring ID for this server.",
  :required => "optional",
  :type => "string",
  :default => "env:RS_INSTANCE_UUID",
  :recipes => ["rll::enable-monitoring"]

attribute   "ENABLE_AUTO_UPGRADE",
  :display_name => "Enables auto upgrade of RightLink10",
  :required => "optional",
  :type => "string",
  :default => "true",
  :choice => ["true", "false"],
  :recipes => ["rll::setup-automatic-upgrade"]

attribute   "UPGRADES_FILE_LOCATION",
  :display_name => "External location of 'upgrades' file",
  :required => "optional",
  :type => "string",
  :default => "https://rightlink.rightscale.com/rightlink/upgrades",
  :recipes => ["rll::upgrade"]
