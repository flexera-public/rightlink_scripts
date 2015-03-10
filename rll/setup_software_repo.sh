#! /bin/bash -ex
set -ex

#
# Ubuntu / Debian
#
if [ -d /etc/apt ]; then
  # Add RightScale software, primarily for monitoring (collectd). We build packages for ubuntu, but not debian.
  # Packages are often compatible though, see this handy table of equivalence, pulled off askubuntu:
  # 14.04 - 14.10        jessie
  # 11.10 - 13.10        wheezy
  # 10.04 - 11.04        squeeze
  distro_codename=`lsb_release -cs`
  case $distro_codename in
  jessie) distro_codename=trusty;;
  wheezy) distro_codename=precise;;
  squeeze) distro_codename=lucid;;
  esac
    
  if [[ -e /usr/bin/curl ]]; then
    curl -s http://mirror.rightscale.com/rightlink/rightscale.pub | apt-key add -
  else
    wget -q -O- http://mirror.rightscale.com/rightlink/rightscale.pub | apt-key add -
  fi
  cat >/etc/apt/sources.list.d/rightscale.sources.list <<EOF
deb [arch=amd64] http://mirror.rightscale.com/rightscale_software_ubuntu/latest $distro_codename main
deb-src [arch=amd64] http://mirror.rightscale.com/rightscale_software_ubuntu/latest $distro_codename main
EOF
  time apt-get -qy update
  time apt-get -qy install unattended-upgrades

#
# CentOS
#
elif [[ `cat /etc/redhat-release` =~ ^CentOS.*\ ([0-9])\. ]]; then
  ver=${BASH_REMATCH[1]}
  case $ver in
  6) if ! yum list installed epel-release-6-8.noarch; then
       rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
       sed -i 's/https/http/' /etc/yum.repos.d/epel.repo # versions of 6.x have trouble with https...
     fi
     time yum -y install yum-plugin-security
     time yum -y --security update-minimal
     ;;
  7) rpm --import http://mirror.rightscale.com/rightlink/rightscale.pub
     cat > /etc/yum.repos.d/RightScale-Software.repo <<EOF
[rightscale]
name=RightScale
baseurl=http://mirror.rightscale.com/rightscale_software/centos/${ver}/x86_64
gpgcheck=1
gpgkey=http://mirror.rightscale.com/rightlink/rightscale.pub
EOF
     time yum -y install yum-plugin-security
     time yum -y --security update-minimal
     ;;
  esac

#
# RedHat
#
elif [[ `cat /etc/redhat-release` =~ ^Red\ Hat.*\ ([0-9])\. ]]; then
  ver=${BASH_REMATCH[1]}
  case $ver in
  6)
    if ! yum list installed epel-release-6-8.noarch; then
      rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
    fi
    time yum -y install yum-plugin-security
    time yum -y --security update-minimal
    ;;
  7) 
    if ! yum list installed epel-release-7-5.noarch; then
      rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
    fi
    cat > /etc/yum.repos.d/RightScale-Software.repo <<EOF
[rightscale]
name=RightScale
baseurl=http://mirror.rightscale.com/rightscale_software/centos/${ver}/x86_64
gpgcheck=1
gpgkey=http://mirror.rightscale.com/rightlink/rightscale.pub
EOF
    time yum -y install yum-plugin-security
    # update-minimal fails on RHEL7, see https://bugzilla.redhat.com/show_bug.cgi?id=1048584
    time yum -y --security update
    ;;
  esac

#
# AWS-Linux
#
elif [[ `cat /etc/system-release` =~ ^Amazon\ Linux.*\ ([0-9]+)\. ]]; then
  ver=${BASH_REMATCH[1]}
  case $ver in
  2014)
    cat > /etc/yum.repos.d/RightScale-Software.repo <<EOF
[rightscale]
name=RightScale
baseurl=http://mirror.rightscale.com/rightscale_software/centos/7/x86_64
gpgcheck=1
gpgkey=http://mirror.rightscale.com/rightlink/rightscale.pub
enabled=1
priority=5
EOF
    time yum -y install yum-plugin-security
    # update-minimal fails on RHEL7, see https://bugzilla.redhat.com/show_bug.cgi?id=1048584
    time yum -y --security update
    ;;
  esac

fi

if [ ! -z "$HOSTNAME" ]; then
  prefix=
  suffix=
  re='[-A-Za-z0-9][-A-Za-z0-9.]*[-A-Za-z0-9]$'
  if [[ "$HOSTNAME" =~ $re ]]; then
    suffix=${BASH_REMATCH[1]}
  fi
  re='^[-A-Za-z0-9][-A-Za-z0-9.]*[-A-Za-z0-9]'
  if [[ "$HOSTNAME" =~ $re ]]; then
    prefix=${BASH_REMATCH[1]}
  fi
  if (( ${#prefix} >= ${#suffix} && ${#prefix} > 1 )); then
    echo "Setting hostname to \$HOSTNAME prefix '$prefix'"
    hostname "$prefix"
  elif (( ${#suffix} > 1 )); then
    echo "Setting hostname to \$HOSTNAME suffix '$suffix'"
    hostname "$suffix"
  fi
fi
