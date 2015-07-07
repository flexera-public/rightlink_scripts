#! /bin/bash -e

# RightScale provides mirrors of some OS distributions. Snapshots of these mirrors
# are taken daily so that any the mirrors can be "frozen" to any given day. These
# mirrors also usually come from a fixed IP range for firewall friendliness. The
# mirrors may be browsed at mirror.rightscale.com. For further information, see
# https://support.rightscale.com/12-Guides/RightScale_101/System_Architecture/Rightscale_OS_Software_Mirrors/.
# The following are available:
#   Ubuntu main, universe, security-updates mirrors (/ubuntu_daily)
#   CentOS Base, addons, extras, update mirrors (/centos)
#   Fedora EPEL (/epel)
#   Rubygems (/rubygems)

# Mirrors are currently only supported for the following distros:
#   Ubuntu 12.04/14.04, CentOS 6/7
# Additionally, on Redhat 6/7 Fedora EPEL will be set up, but not the main repository mirrors.

# To enable this functionality, have this script be the FIRST script in your
# boot sequence. The following parameters are accepted:
#   FREEZE_DATE - The date from which to pull OS/EPEL software. Accepts following parameters:
#       empty string - disables usage of frozen mirrors (use config already on disk)
#       YYYY-MM-DD - i.e 2015-06-01
#       latest - today's date
#   RUBYGEMS_FREEZE_DATE -  Date from which to pull Rubygems software. Same parameters as above.
#   MIRROR_HOST - host, possible values:
#     ENV:RS_ISLAND - Island load balancers for your RightScale account. Note that this
#                     is NOT guaranteed to be geographically closest, but is rather
#                     assigned per acocunt
#     cf-mirror.rightscale.com - CloudFront version of mirror.rightscale.com

FREEZE_DATE=${FREEZE_DATE//-/}
if [[ -z "$FREEZE_DATE" ]]; then
  echo "Since FREEZE_DATE is not set, not configuring RightScale software mirrors"
elif [[ ! "$FREEZE_DATE" =~ ^[0-9]{8}$ ]] && [[ ! "$FREEZE_DATE" = "latest" ]]; then
  echo "If FREEZE_DATE is set, it must be either 'latest' or in the format YYYY-MM-DD"
  exit 1
fi
today=$(date +"%Y%m%d")
if [[ "$FREEZE_DATE" =~ ^[0-9]{8}$ ]] && [[ $FREEZE_DATE -gt $today ]]; then
  echo "FREEZE_DATE can't be from a date in the future"
  exit 1
fi

RUBYGEMS_FREEZE_DATE=${RUBYGEMS_FREEZE_DATE//-/}
if [[ -z "$RUBYGEMS_FREEZE_DATE" ]]; then
  echo "Since RUBYGEMS_FREEZE_DATE is not set, not configuring Rubygems mirror"
elif [[ ! "$RUBYGEMS_FREEZE_DATE" =~ ^[0-9]{8}$ ]] && [[ ! "$RUBYGEMS_FREEZE_DATE" = "latest" ]]; then
  echo "If RUBYGEMS_FREEZE_DATE is set, it must be either 'latest' or in the format YYYY-MM-DD"
  exit 1
fi
today=$(date +"%Y%m%d")
if [[ "$RUBYGEMS_FREEZE_DATE" =~ ^[0-9]{8}$ ]] && [[ $RUBYGEMS_FREEZE_DATE -gt $today ]]; then
  echo "RUBYGEMS_FREEZE_DATE can't be from a date in the future"
  exit 1
fi

if [[ -n "$FREEZE_DATE" ]] || [[ -n "$RUBYGEMS_FREEZE_DATE" ]]; then
  if [[ -z "$MIRROR_HOST" ]]; then
    echo "MIRROR_HOST cannot be blank, possible values are cf-mirror.rightscale.com or ENV:RS_ISLAND"
  elif [[ ! "$MIRROR_HOST" =~ island|mirror ]]; then
    echo "MIRROR_HOST (= $MIRROR_HOST) appears to be invalid, possible values are cf-mirror.rightscale.com or ENV:RS_ISLAND"
    exit 1
  fi
fi

distro=unknown
distro_ver=unknown
if which apt-get >/dev/null 2>&1; then
  if [[ -f /etc/lsb-release ]]; then
    . /etc/lsb-release
    distro=${DISTRIB_ID:-unknown}
    distro_ver=${DISTRIB_RELEASE:-unknown}
    distro_codename=${DISTRIB_CODENAME:-unknown}
  fi
elif [[ -f /etc/redhat-release ]]; then
  if [[ $(cat /etc/redhat-release) =~ ^([^0-9]+)\ ([0-9])\. ]]; then
    distro="${BASH_REMATCH[1]}"
    distro=${distro/Red Hat/RedHat}
    distro_ver="${BASH_REMATCH[2]}"
    distro_ver=$(echo $distro_ver | cut -d. -f1)
  fi
fi
distro=$(echo $distro | cut -d' ' -f1 | tr [:upper:] [:lower:])
arch_info=$(echo $(uname -i 2>/dev/null)$(uname -m 2>/dev/null))
if [[ arch_info =~ 386|686 ]]; then
  arch=i386
else
  arch=x86_64
fi

freeze_date_msg=$FREEZE_DATE
if [[ -z "$FREEZE_DATE" ]]; then
  freeze_date_msg='(unconfigured)'
fi
rubygems_freeze_date_msg=$RUBYGEMS_FREEZE_DATE
if [[ -z "$RUBYGEMS_FREEZE_DATE" ]]; then
  rubygems_freeze_date_msg='(unconfigured)'
fi
echo "Distro: $distro"
echo "Distro version: $distro_ver"
echo "Architecture: $arch"
echo "OS Repositories Freeze Date: $freeze_date_msg"
echo "Rubygems Freeze Date: $RUBYGEMS_FREEZE_DATE"

function content_changed() {
  sudo [ ! -f "$1" ] || [[ "$(checksum $2)" != "$(checksum $1)" ]]
}

# Get the SHA256 checksum of a file.
# $1: the file path to get the checksum from
function checksum() {
  sudo sha256sum $1 | cut -d ' ' -f 1
}

function checklink() {
  curl -sSf --retry 3 --max-time 60 >/dev/null --head $1 >/dev/null
}

# Add a temporary file to the list of temporary files to clean up on exit.
# $@: one or more file paths to add to the list
declare -a mktemp_files
trap 'sudo rm --force "${mktemp_files[@]}"' EXIT
function add_mktemp_file() {
  mktemp_files=("$@" "${mktemp_files[@]}")
}

# Overwrite and backup a reposity configuration file if it has changed
# $1: File name to write
# $@: Lines to write to file
function write_cfg() {
  local file=$1
  shift

  # Create a temporary file for the collectd plugin configration
  local file_tmp=$(sudo mktemp "${file}.XXXXXXXXXX.orig")
  add_mktemp_file $file_tmp

  # Add each line
  for line in "$@"; do
    echo "$line" | sudo tee -a $file_tmp >/dev/null 2>&1
  done

  # Overwrite and backup the collectd plugin configration if it has changed
  if content_changed $file $file_tmp; then
    echo "  Writing $file"
    sudo chmod 0644 $file_tmp
    sudo [ -f $file ] && sudo cp --archive $file "${file}.$(date -u +%Y%m%d%H%M%S)"
    sudo mv --force $file_tmp $file
  else
    echo "  Contents of $file unchanged"
  fi
}

function no_index_error() {
  echo "ERROR: failed to configure RightScale mirrors because we could not fetch repository"
  echo "index from $1. Reasons for this could include:"
  echo "  * A bad FREEZE_DATE (too new or old)."
  echo "  * An unsupported OS or OS version. For example LTS Ubuntu releases are supported"
  echo "    but other ones are not."
  echo "  * Connectivity issues caused by your networking setup."
  exit 1
}


########################
# Main OS
########################
if [[ -n "$FREEZE_DATE" ]]; then
  mirror_base="http://$MIRROR_HOST"
  case $distro in
  redhat|centos)
    freezedate="$FREEZE_DATE"
    ;;
  ubuntu)
    if [[ "$FREEZE_DATE" == "latest" ]]; then
      freezedate="latest"
    else
      freezedate="${FREEZE_DATE:0:4}/${FREEZE_DATE:4:2}/${FREEZE_DATE:6:2}"
    fi
    ;;
  *)
    echo "ERROR: Not configuring RightScale mirrors. Only Ubuntu and CentOS/RHEL distros are supported."
    echo "You may disable this script by letting FREEZE_DATE to an empty string or ignore."
    exit 1
  esac

  case $distro in
  centos)
    echo "Setting up CentOS repositories at $mirror_base"
    if [[ "$distro_ver" == "5" ]]; then
      components="Base centosplus updates extras addons"
    else
      components="Base centosplus updates extras"
    fi

    for component in $components; do
      if [[ "$component" == "Base" ]]; then
        component_dir="os"
      else
        component_dir="$component"
      fi
      component_url="$mirror_base/centos/$distro_ver/$component_dir/$arch/archive/$freezedate"

      if [[ "$component_dir" == "os" ]]; then
        if ! checklink "$component_url/repodata/repomd.xml"; then
          no_index_error $component_url
        fi
      fi

      write_cfg "/etc/yum.repos.d/CentOS-$component.repo" \
        "[$component]" \
        "name=none" \
        "baseurl=$component_url" \
        "failovermethod=priority" \
        "gpgcheck=1" \
        "enabled=1" \
        "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-$distro_ver"
    done

    sudo yum clean all
    echo "Ran 'yum clean all'"
    ;;
  ubuntu)
    echo "Setting up Ubuntu repositories at $mirror_base/ubuntu_daily/$freezedate"

    src=/etc/apt/sources.list
    echo "Writing Ubuntu repo config to $src"
    write_cfg $src \
      "deb $mirror_base/ubuntu_daily/$freezedate $distro_codename main restricted multiverse universe" \
      "deb $mirror_base/ubuntu_daily/$freezedate $distro_codename-updates main restricted multiverse universe" \
      "deb $mirror_base/ubuntu_daily/$freezedate $distro_codename-security main restricted multiverse universe"
    echo "Running apt-get update"
    if ! sudo apt-get update > /dev/null; then
      no_index_error "$mirror_base/ubuntu_daily/$freezedate"
    fi
    ;;
  esac
fi

########################
# Fedora EPEL
# Set FREEZE_DATE to be same as for OS as a simplification
########################
if [[ -n "$FREEZE_DATE" ]]; then
  case $distro in
  redhat|centos)
    # Install the EPEL GPG key. RS_ATTACH_DIR covers RightScript case, attachments for git case.
    attachments=${RS_ATTACH_DIR:-attachments}
    epel_file_location=/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$distro_ver
    echo "Installing EPEL GPG key to $epel_file_location"
    sudo cp $attachments/RPM-GPG-KEY-EPEL-$distro_ver $epel_file_location

    epel_url="$mirror_base/epel/$distro_ver/$arch/archive/$freezedate"
    echo "Setting up Fedora EPEL repository at $epel_url"
    if ! checklink "$epel_url/repodata/repomd.xml"; then
      no_index_error $epel_url
    fi
    src=/etc/yum.repos.d/Epel.repo
    write_cfg $src \
      "[epel]" \
      "name=EPEL" \
      "baseurl=$epel_url" \
      "failovermethod=priority" \
      "gpgcheck=1" \
      "enabled=1" \
      "gpgkey=file://$epel_file_location"
    ;;
  esac
fi


########################
# Rubygems
# Make this optional as well, most people probably manage this via bundler nowadays.
########################
if [[ -n "$RUBYGEMS_FREEZE_DATE" ]]; then
  gems_url="$mirror_base/rubygems/archive/$RUBYGEMS_FREEZE_DATE/"
  echo "Configuring rubygems to use mirror $gems_url"
  if ! which gem >/dev/null 2>&1; then
    echo "Ruby is not installed. Installing mirror configuration anyways in case it is installed at a later date."
  fi
  write_cfg "/etc/gemrc" \
    "---" \
    "update: --no-rdoc --no-ri" \
    "install: --no-rdoc --no-ri" \
    ":benchmark: false" \
    ":verbose: false" \
    ":update_sources: true" \
    ":bulk_threshold: 1000" \
    ":backtrace: false" \
    ":sources:" \
    "- $mirror_base/rubygems/archive/$RUBYGEMS_FREEZE_DATE/"
fi
