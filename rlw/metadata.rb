name        "rlw"
maintainer  "RightScale, Inc."
license     "see LICENSE file in repository root"
description "Base scripts for RightLink10 on Windows (RLL) to initialize basic functionality"
version     '0.2015.2646234889'

recipe      "rlw::wait-for-eip", "Wait for external IP address to be assigned (EC2 issue)"
recipe      "rlw::install_updates", "Installs windows updates"
recipe      "rlw::install_updates_by_kb", "Microsoft KB number of update to be installed"
recipe      "rlw::setup_hostname", "Changes the hostname of the server"
recipe      "rlw::ssc", "Installs and configures SSC for RightScale monitoring"
recipe      "rlw::upgrade", "Check whether a RightLink upgrade is available and do the upgrade"
recipe      "rlw::update_policy", "Define the Windows automatic update policy for the instance"
recipe      "rlw::shutdown-reason", "Print out the reason for shutdown"
recipe      "rlw::setup_automatic_upgrade", "Periodically checks if an upgrade is available and upgrade if there is."
recipe      "rlw::test-script", "Test operational script, used by righlinklite/tester"

attribute   "SERVER_HOSTNAME",
  :display_name => "Hostname for this server",
  :description => "The server's hostname may contain letters (a-z, A-Z), numbers (0-9), and hyphens (-), " +
  "but no spaces or periods (.). The name may not consist entirely of digits, and " +
  "may not be longer than 63 characters.",
  :required => "optional",
  :type => "string",
  :default => "env:RS_SERVER_NAME",
  :recipes => ["rlw::setup_hostname"]

attribute   "WINDOWS_UPDATES_REBOOT_SETTING",
  :display_name => "Setting whether to reboot automatically",
  :description => "Specify how the Windows automatic updates should be applied to a running server. " +
  "For example, you may not want the server to automatically reboot itself after applying an update. " +
  "Set to 'Allow Reboot' for automatic reboots.",
  :required => "optional",
  :type => "string",
  :choice => ["Do Not Allow Reboot", "Allow Reboot"],
  :default => "Do Not Allow Reboot",
  :recipes => ["rlw::install_updates", "install_updates_by_kb"]

attribute   "WINDOWS_AUTOMATIC_UPDATES_POLICY",
  :display_name => "SSC version to use",
  :required => "optional",
  :type => "string",
  :choice => ["Disable automatic updates", "Notify before download",
              "Notify before installation", "Install updates automatically"],
  :default => "Disable automatic updates",
  :recipes => ["rlw::update_policy"]

attribute   "KB_ARTICLE_NUMBER",
  :display_name => "Microsoft KB Article to download and install",
  :required => "optional",
  :type => "string",
  :recipes => ["rlw::install_updates_by_kb"]

attribute   "SSC_SERV_VERSION",
  :display_name => "SSC version to use",
  :required => "optional",
  :type => "string",
  :default => "3.5.0",
  :recipes => ["rlw::install_updates"]

attribute   "SSC_SERV_PLATFORM",
  :display_name => "SSC platform to use",
  :required => "optional",
  :type => "string",
  :default => "x86-64",
  :recipes => ["rlw::ssc"]

attribute   "RS_INSTANCE_UUID",
  :display_name => "RightScale monitoring ID for this server",
  :required => "optional",
  :type => "string",
  :default => "env:RS_INSTANCE_UUID",
  :recipes => ["rlw::ssc"]

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
