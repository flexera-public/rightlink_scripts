name        "rll"
maintainer  "Thorsten von Eicken"
license     "see LICENSE file in repository root"
description "Base scripts for RightLink10 (RLL) to initialize basic functionality"
version     "10.0.0"

recipe      "rll::wait-for-eip", "Wait for external IP address to be assigned (EC2 issue)"
recipe      "rll::init", "Initializes repositories and minor RLL-related things"
recipe      "rll::collectd", "Installs and configures collectd for RightScale monitoring"
recipe      "rll::upgrade", "Check whether a RightLink upgrade is available and do the upgrade"
recipe      "rll::test-script", "Test operational script, doesn't do anything useful"
recipe      "rll::shutdown-reason", "Print out the reason for shutdown"

attribute   "HOSTNAME",
  :display_name => "Hostname for this server",
  :description => "The sever's hostname is set to the longest valid prefix or suffix of " +
	"this variable. E.g. 'my.example.com V2', 'NEW my.example.com', and " +
	"'database.io my.example.com' all set the hostname to 'my.example.com'. " +
	"Set to an empty string to avoid any change to the hostname.",
  :required => "optional",
  :type => "string",
  :default => "env:RS_SERVER_NAME",
  :recipes => ["rll::init"]

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

attribute   "VAR",
  :display_name => "random variable to print",
  :required => "recommended",
  :type => "string",
  :default => "test value",
  :recipes => ["rll::test-script"]

attribute   "CRED",
  :display_name => "some credential",
  :required => "recommended",
  :type => "string",
  :default => "cred:AWS_ACCESS_KEY_ID",
  :recipes => ["rll::test-script"]

