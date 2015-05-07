#! /bin/bash -x

source /var/lib/rightscale-identity
if [[ -z "$expected_public_ip" ]]; then
  echo "No public IP address to wait for"
  exit 0
fi

rfc1918="^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)"
if [[ "$expected_public_ip" =~ rfc1918 ]]; then
  echo "External IP is within rfc1918 range: $expected_public_ip, not waiting"
  exit 0
fi
echo "Expecting to be assigned public IP $expected_public_ip"

targets=(my.rightscale.com us-3.rightscale.com us-4.rightscale.com island1.rightscale.com island10.rightscale.com $api_hostname)
echo "Checking public IP against ${targets[@]}"

# spend at most a few minutes waiting for nobody to tell us that we have the wrong IP address
bad_ip=true
t0=`date +%s`
while [[ "$bad_ip" == true && $((`date +%s` - $t0 < 300)) ]]; do
  bad_ip=false
  for t in "${targets[@]}"; do
    x=`curl --max-time 1 -S -s http://$t/ip/mine`
    if [[ "$x" =~ ^[.0-9]*$ && ! "$x" =~ ^127\. && "$x" != "$expected_public_ip" ]]; then
      echo "$t responded with $x which is not the $expected_public_ip we expect"
      bad_ip=true
      sleep 5
    else
      echo "$t responded with $x"
    fi
  done
done
echo "No incorrect public IP address detected after $(((`date +%s` - $t0))) seconds"
