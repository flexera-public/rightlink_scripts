#! /bin/bash -x

rs_vars=$(sudo cat /var/lib/rightscale-identity)

re="expected_public_ip='([^']+)'"
if [[ "$rs_vars" =~ $re ]]; then
  expected_public_ip="${BASH_REMATCH[1]}"
fi

if [[ -z "$expected_public_ip" ]]; then
  echo "No public IP address to wait for"
  exit 0
fi

rfc1918="^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)"
if [[ "$expected_public_ip" =~ $rfc1918 ]]; then
  echo "External IP is within rfc1918 range: $expected_public_ip, not waiting"
  exit 0
fi
echo "Expecting to be assigned public IP $expected_public_ip"

re="api_hostname='([^']+)'"
if [[ "$rs_vars" =~ $re ]]; then
  api_hostname="${BASH_REMATCH[1]}"
fi

targets=(my.rightscale.com us-3.rightscale.com us-4.rightscale.com island1.rightscale.com island10.rightscale.com $api_hostname)
echo "Checking public IP against ${targets[@]}"

# spend at most a few minutes waiting for nobody to tell us that we have the wrong IP address
bad_ip=true
t0=`date +%s`
while [[ "$bad_ip" == true && $((`date +%s` - $t0 < 300)) ]]; do
  bad_ip=false
  # check each API host
  for target in "${targets[@]}"; do
    # query the API for the servers IP address
    my_ip=$(curl --max-time 1 -S -s http://$target/ip/mine)
    if [[ "$my_ip" =~ ^[.0-9]*$ && ! "$my_ip" =~ ^127\. && "$x" != "$expected_public_ip" ]]; then
      echo "$target responded with: $my_ip which is not the IP we expect: $expected_public_ip"
      bad_ip=true
      break
    else
      echo "$target responded with $my_ip"
    fi
  done
  sleep 5
done

if [[ "$bad_ip" == true ]]; then
  echo "One or more API Hosts is returning an IP address that is different than expected"
  exit 1
else
  echo "No incorrect public IP address detected after $(((`date +%s` - $t0))) seconds"
fi
