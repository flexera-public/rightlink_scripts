#! /bin/bash -ex
# Copyright (c) 2008-2011 RightScale, Inc, All Rights Reserved Worldwide.

#
# Drop to lower case, since hostnames should be lc anyway.
#
HOSTNAME=$(echo $HOSTNAME | tr "[:upper:]" "[:lower:]")

#
# Support optional server namspacing
# And store the namespace in /etc/namespace
#
# Example: "crimson:broker1-1.rightscale.com"
#
if (echo $HOSTNAME | grep -q ":"); then
  namespace=`echo $HOSTNAME | cut -d: -f1`
  HOSTNAME=`echo $HOSTNAME | cut -d: -f2`
  echo $namespace > /etc/namespace
  echo "Found namespaced hostname: NAMESPACE='$namespace' HOSTNAME='$HOSTNAME'"
fi

#
# Check for a numeric suffix (like in a server array)
# example:  array name #1
#
if [ $( echo $HOSTNAME | grep "#" -c ) -gt 0 ]; then
  numeric_suffix=$( echo $HOSTNAME | cut -d'#' -f2 )  
else
  # no suffix
  numeric_suffix=""
fi

# Strip off "znew", or "zold" prepend.
HOSTNAME=${HOSTNAME#znew}
HOSTNAME=${HOSTNAME#zold}

# Strip off a leading "-"'s or leading whitespace, if there is any.
HOSTNAME=${HOSTNAME##*( |-)}

# Clean up the hostname, so we can put labels after hostnames
# with no problems (like 'sketchy1-10.rightscale.com MY COMMENT')
HOSTNAME=$(echo $HOSTNAME | cut -d' ' -f 1)

# Underscores are illegal in hostnames, so change them to dashes.
HOSTNAME=$(echo $HOSTNAME | sed "s/_/-/")

# Append a numeric suffix to the sname, if we have one.
if [ ! -z $numeric_suffix ]; then
  echo "Appending array suffix $numeric_suffix to the sname"
  sname=$(echo $HOSTNAME | cut -d'.' -f 1)
  dname=${HOSTNAME#"$sname"}

  HOSTNAME="$sname-$numeric_suffix$dname"
else 
  echo "No suffix found, not appending anything."
fi

echo "setting hostname to: $HOSTNAME"
hostname $HOSTNAME

# make sure $HOSTNAME is valid, or RightLink/Ohai/Chef will crash
# it doesn't have to point to our IP, it just has to resolve.
(ip_addr=$(dig $HOSTNAME +short)) || true

if [ -z "$ip_addr" ]; then
  echo "WARNING!  The hostname you're attempting to use is NOT valid!"
  echo "Putting a local lookup in /etc/hosts as a work around."
  echo -e "\n127.0.0.1  $HOSTNAME\n" >> /etc/hosts 
fi

# Set the default hostname, so it'll stick even after a DHCP update
echo "$HOSTNAME" > /etc/hostname

# Fix the 127.0.1.1 record, so ubuntu sudo will still work, in case we ever want to use it.
short_hostname=$(echo $HOSTNAME | cut -d'.' -f1)
sed -i "s%^127.0.1.1.*%127.0.1.1 $HOSTNAME $short_hostname%" /etc/hosts
