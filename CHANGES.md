Changelog for the RightLink10 Base ServerTemplate
=================================================

unreleased changes
------
- Moved UPGRADES_LOCATION parameter from rll/upgrade.sh to rll/setup-automatic-upgrade.sh and from rlw/upgrade.sh to rlw/setup-automatic-upgrade.sh. Added a new parameter UPGRADE_VERSION to rll/upgrade.sh and rlw/upgrade.sh to accept a simple text version to upgrade to, i.e. '10.5.4'
- Add setup-ntp.sh and setup-ntp.ps1 to Boot scripts. These scripts setup the NTP daemon to synchronize system time, by default to time.rightscale.com. Accurate time is important for monitoring and proper functioning of the client.
- Use RightLink built-in monitoring for CentOS 7/RHEL 7 due to a broken write_http plugin: https://github.com/collectd/collectd/issues/1996
- Avoid re-install of selinux policy for enable-managed-login.sh if possible.

10.5.3
------
- Added rll/redhat-subscription-register.sh (RL10 Linux RedHat Subscription Register) and rll/redhat-subscription-unregister.sh (RL10 Linux RedHat Subscription Unregister) which registers and unregisters a RedHat instance from the RedHat subscription service

10.5.2
------
- Update attachment libnss_rightscale.tgz for rll/enable-managed-login.sh to work for users with very low rightscale ids (< 500)
- Added rll/base.yml and rlw/base.yml ServerTemplate YAML files for use with right_st; these also include a set of best
  practice alerts.
- Added rll/setup-alerts.sh and rlw/setup-alerts.ps1 RightScripts which dynamically change alerts defined on running
  instances so they match the actual metrics sent. The alerts with metrics that need this are network interfaces (both
  Linux and Windows), swap space (can be enabled or disable on Linux), and disk usage (there is a different metric name
  with collectd 4).

10.5.1
------
- Update README.md with development workflow using right_st and RightScripts
- Improve rll/enable-managed-login.sh (RL10 Linux Enable Managed Login) to determine OS

10.5.0
------
- Added rll/enable-managed-login.sh (RL10 Linux Enable Managed Login) which installs the RightScale NSS plugin, and updates PAM and SSH configuration to allow SSH connectivity to RightScale accounts
- Added rll-examples/install-packages.sh (SYS packages install) which installs packages required by RightScripts
- Set inputs for 'RL10 Linux Enable Monitoring' and 'RL10 Linux Enable Docker Support (Beta)' to be required

10.4.0
------
- Have hostname persist on reboot as it may reset based on OS
- Update and add counter- and gauge- instance names for the example Windows monitoring scripts
- Use the lastest EPEL repository for RHEL/CentOS 6 and 7 when installing collectd
- Creation of enable-docker.sh (RL10 Linux Enable Docker Support (Beta)) RightScript

10.3.1
------
- Documented the use of the Go based `right_st` tool instead of the `rightscript_sync` Ruby tool
- Cleaned up RightScripts to pass `right_st validate`

10.3.0
------
- Update scripts with support for CoreOS
- Replaced rll/collectd.sh with rll/enable-monitoring.sh (RL10 Linux Enable Monitoring)
- Fix upgrade script audit entry sometimes getting cut short

10.2.1
------
- Fix variable name and comments in wait-for-eip.ps1

10.2.0
------
- Add retry commands to apt-get and yum commands for script robustness
- Add RightScript metadata to all scripts and rightscript_sync gem
- Fix collectd.sh script failure on CentOS 6 when SELinux is enabled.
- Update rlw::shutdown-reason to have parity with Linux counterpart.
- Move example scripts to their own cookbooks
- Add RightScript metadata to scripts
- Remove testing scripts

10.1.4
------
- Added rll-compat::rightscale-mirrors for configuring RightScale-hosted OS repository mirrors

10.1.3
------
- shutdown-reason.sh now exports DECOM_REASON as an environment variable which will
  be one of service_restart, stop, terminate, or reboot.
- Have setup_hostname.sh add hostname to /etc/hosts to avoid sudo warnings
- Changed test.sh script inputs

10.1.2
------
- Make collectd.sh throw errors on broken configs.

10.1.rc1
--------
- Changes to use RightScale TSS for monitoring:
  - Modified collectd config to use write_http plugin to route monitoring traffic through RightLink.
  - Removed usage of forward ported collectd 4 and RightScale Software repo.
  - Renamed setup_software_repo.sh to security_updates.sh.
- Fixed syntax errors in wait-for-eip.sh

10.1.rc0
--------
- Modified wait-for-eip.sh to reflect variable name changes
- Update scripts to use sudo as RightLink now runs as the rightlink user and not as root

10.0.rc4
--------
- Fixing of rs_push script to find the right audit entry again (html parsing breakage)
- Adding test-script back into rll cookbook to support the rightlinklite regression tests

10.0.3
------
- Reorg of rll cookbook scripts to break out the init script into multiple pieces
- Addition of automatic upgrades

10.0.rc0 .. 10.0.rc2
--------------------
- Dark ages... First version of the rll "cookbook" and the rs_push/rs_make_st scripts
