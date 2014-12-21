#! /bin/bash -e
prefix=https://rightlinklite.rightscale.com/rll
re="RLL ([^ ]*) "
$RLBIN -version
if [[ `$RLBIN -version` =~ $re ]]; then
  current=${BASH_REMATCH[1]}
else
  echo "Can't determine current version of RLL"
  $RLBIN -version
  exit 1
fi

# Fetch information about what we should become, the "upgrade" file consists
# of lines with "current_version:new_version"
match=`curl -sS --retry 3 $prefix/self_upgrade2/upgrades | egrep "^${current}:" || true`
re="^${current}: *([^ ]*)"
if [[ "$match" =~ $re ]]; then
  desired=${BASH_REMATCH[1]}
else
  echo "Cannot determine latest version from upgrade file"
  echo "Tried to match /^${current}:/ in $prefix/self_upgrade2/upgrades"
  # we let the script succeed here
  exit 0
fi

if [[ "$desired" == "$current" ]]; then
  echo "RLL is up-to-date (current=$current)"
  exit 0
fi

echo "RLL needs an upgrade(/downgrade):"
echo "  from current=$current"
echo "  to   desired=$desired"
 
echo "downloading RLL version '$desired'"
# code duplicated from rightlink.boot.sh
cd /tmp
rm -rf rll rll.tgz
curl -sS --retry 3 -o rll.tgz $prefix/$desired/rightlinklite.tgz
tar zxf rll.tgz || (cat rll.tgz; exit 1)
# code duplicated from rightlink.install.sh
mv rll/rightlinklite $RLBIN-new

echo "checking new version"
new=`$RLBIN-new -version`
if [[ "$new" =~ $desired ]]; then
  echo "new version looks right: $new"
  echo "restarting RLL to pick up new version"
  source /var/run/rll-secret
  res=`curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET \
    "http://127.0.0.1:$RS_RLL_PORT/rll/upgrade?exec=$RLBIN-new"`
  if [[ $res =~ successful ]]; then
    mv $RLBIN $RLBIN-old
    cp $RLBIN-new $RLBIN
    echo DONE
  else
    echo "Error: $res"
    exit 1
  fi
else
  echo "OOPS, new version doesn't look right:"
  echo $new
  exit 1
fi
