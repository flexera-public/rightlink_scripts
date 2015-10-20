Changelog for the RightLink10 Base ServerTemplate
=================================================

Unreleased Changes
------------------
- Update scripts with support for CoreOS

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
