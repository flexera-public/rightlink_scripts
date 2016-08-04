#! /bin/bash
# ---
# RightScript Name: SYS packages install
# Description: |
#   Installs packages required by RightScripts, or extra packages.
#   To handle naming variations, prefix package names with "yum:" or "apt:".
# Inputs:
#   PACKAGES:
#     Input Type: single
#     Category: RightScale
#     Description: Space-separated list of additional packages.
#     Default: blank
#     Required: false
#     Advanced: true
# ...

if [ -z "$RS_PACKAGES" -a -z "$PACKAGES" ]; then
  echo "No packages to install"
  exit 0
fi

if [ -n "$PACKAGES" -a -n "$RS_PACKAGES" ]; then
  packages="$RS_PACKAGES $PACKAGES"
elif [ -n "$PACKAGES" ]; then
  packages=$PACKAGES
else
  packages=$RS_PACKAGES
fi

if which apt-get > /dev/null 2>&1; then
  pkgman=apt
elif which yum > /dev/null 2>&1; then
  pkgman=yum
fi

if [ -z "$pkgman" ]; then
  echo "ERROR: Unrecognized package manager, but we have packages to install"
  exit 1
else
  echo "Detected package manager: $pkgman"
fi

# Determine which packages are suitable for install on this system.
declare -a list
sz=0
for pkg in $packages; do
  echo $pkg | grep --extended-regexp --quiet '^[a-z0-9_]+:'
  selective=$?
  echo $pkg | grep --extended-regexp --quiet "^$pkgman:"
  matching=$?
  pkg=`echo $pkg | sed -e s/^$pkgman://`
  if [ $selective == 0 -a $matching == 0 ]
  then
    # Package is selective (begins with pkgman:) AND the pkgman matches ours;
    # it is a candidate for install.
    list[$sz]=$pkg
    let sz=$sz+1
  elif [ $selective != 0 ]
  then
    # Package is not selective (it has the same name for every pkgman). It is
    # a candidate for install.
    list[$sz]=$pkg
    let sz=$sz+1
  fi
done

if [ -n "$list" ]; then
  echo "Packages required on this system: $list"
else
  echo "No required packages on this system. Already installed: $packages"
  exit 0
fi

set -e
case $pkgman in
  yum)
    sudo yum install -y $list
    ;;
  apt)
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $list
    ;;
  *)
    echo "INTERNAL ERROR in RightScript (unrecognized pkgman $pkgman)"
    exit 2
    ;;
esac
set +e
