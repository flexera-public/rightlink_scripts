# This is a reference script to generate the selinux policy usedin in rll/
#
# Selinux consists of policy files dictating explicit permissions for various
# programs to read/open/write/etc certain system files. The final installed
# object is the .pp (compiled policy file) which is generated from a series of
# permissions described in a .te file. .te file can be generated from piping
# /var/log/audit/audit.log to audit2allow. Following commands will turn that
# into a policy
checkmodule -M -m -o rightscale_login_policy.mod rightscale_login_policy.te
semodule_package -m rightscale_login_policy.mod -o rightscale_login_policy.pp
semodule -i rightscale_login_policy.pp
