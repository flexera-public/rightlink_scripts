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

# spend at most 15 minutes checking the API hosts for either the expected IP address or an incorrect IP address
start_time=$(date +%s)
while [[ $(($(date +%s) - $start_time < 900)) ]]; then
  # reset matching API responses to zero
  matching_responses=0
  # check each API
  for target in "${targets[@]}"; do
    # query the API for the servers IP address
    my_ip=$(curl --max-time 1 -S -s http://$target/ip/mine)
    if [[ "$my_ip" =~ ^[.0-9]*$ && ! "$my_ip" =~ ^127\. && "$my_ip" != "$expected_public_ip" ]]; then
      echo "$target responded with: $my_ip which is not the IP we expect: $expected_public_ip"
    elif [[ "$my_ip" == "$expected_public_ip" ]]; then
      matching_responses+=1
    else
      echo "$target responded with $my_ip"
    fi
  done
  # check to see if all API hosts reported IPs that match the expected IP and exit the script
  if [[ "$matching_responses" == "${#targets[@]}" ]]; then
    echo "All API hosts are reporting the expected IP address: $expected_public_ip"
    exit 0
  else
    echo "One or more API Hosts is returning an IP address that is different than expected"
    echo "Sleeping 15 seconds and retrying ... "
    sleep 15
  fi
done

# if all API hosts are returning the expected IP address after 15 minutes then exit with an error
echo "One or more API Hosts is returning an IP address that is different than expected after $(((`date +%s` - $t0))) seconds"
exit 1
