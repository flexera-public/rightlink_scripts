name        "rlw-examples"
maintainer  "RightScale, Inc."
license     "see LICENSE file in repository root"
description "Example scripts for RightLink10 on Windows (RLW)"
version     '10.2.0'

recipe      "rlw-examples::install-updates", "Installs windows updates"
recipe      "rlw-examples::install-updates-by-kb", "Microsoft KB number of update to be installed"
recipe      "rlw-examples::setup-hostname", "Changes the hostname of the server"
recipe      "rlw-examples::automatic-update-policy", "Define the Windows automatic update policy for the instance"

attribute   "WINDOWS_UPDATES_REBOOT_SETTING",
  :display_name => "Setting whether to reboot automatically",
  :description => "Specify how the Windows automatic updates should be applied to a running server. " +
  "For example, you may not want the server to automatically reboot itself after applying an update. " +
  "Set to 'Allow Reboot' for automatic reboots.",
  :required => "optional",
  :type => "string",
  :choice => ["Do Not Allow Reboot", "Allow Reboot"],
  :default => "Do Not Allow Reboot",
  :recipes => ["rlw-examples::setup-hostname", "rlw-examples::install-updates", "install-updates-by-kb"]

attribute   "WINDOWS_AUTOMATIC_UPDATES_POLICY",
  :display_name => "Windows Automatic Updates Policy",
  :required => "optional",
  :type => "string",
  :choice => ["Disable automatic updates", "Notify before download",
              "Notify before installation", "Install updates automatically"],
  :default => "Disable automatic updates",
  :recipes => ["rlw-examples::automatic-update-policy"]

attribute   "KB_ARTICLE_NUMBER",
  :display_name => "Microsoft KB Article to download and install",
  :required => "optional",
  :type => "string",
  :recipes => ["rlw-examples::install-updates-by-kb"]
