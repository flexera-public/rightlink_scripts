name        "rll-examples"
maintainer  "RightScale, Inc."
license     "see LICENSE file in repository root"
description "Example scripts for RightLink10 on Linux (RLL)"
version     '10.2.0'

recipe      "rll-examples::security-updates", "Installs security updates"
recipe      "rll-examples::rightscale-mirrors", "Setup software repository mirrors hosted by RightScale"

attribute   "MIRROR_HOST",
  :display_name => "OS repository hostname",
  :required => "recommended",
  :description => "RightScale provides mirrors of some OS distributions. This would be the hostname of one of those mirrors (typically env:RS_ISLAND)",
  :type => "string",
  :default => "env:RS_ISLAND",
  :recipes => ["rll-examples::rightscale-mirrors"]

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
