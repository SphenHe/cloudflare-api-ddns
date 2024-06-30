#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Automatically update your CloudFlare DNS record to the IP, Dynamic DNS

# Default config
CFAPI_TOKEN=""
CFUSER=""
CFRECORD_NAME=""
CFZONE_NAME=""

CFTTL=120
FORCE=false

# Get parameter
while getopts 46a:u:h:z:f: opts; do
  case ${opts} in
    4) CFRECORD_TYPE="A"; WANIPSITE="http://ipv4.icanhazip.com" ;;
    6) CFRECORD_TYPE="AAAA"; WANIPSITE="http://ipv6.icanhazip.com" ;;
    a) CFAPI_TOKEN=${OPTARG} ;;
    u) CFUSER=${OPTARG} ;;
    h) CFRECORD_NAME=${OPTARG} ;;
    z) CFZONE_NAME=${OPTARG} ;;
    f) FORCE=${OPTARG} ;;
    *) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
  esac
done

# Validate required settings
if [ -z "$CFRECORD_TYPE" ]; then
  echo "You must specify either -4 for IPv4 or -6 for IPv6."
  exit 2
fi

if [ -z "$CFAPI_TOKEN" ]; then
  echo "Missing API token. Obtain it from https://www.cloudflare.com/a/account/my-account"
  exit 2
fi

if [ -z "$CFUSER" ]; then
  echo "Missing username (email address)."
  exit 2
fi

if [ -z "$CFRECORD_NAME" ]; then
  echo "Missing hostname to update."
  exit 2
fi

# Ensure the hostname is a fully qualified domain name (FQDN)
if [ "$CFRECORD_NAME" != "$CFZONE_NAME" ] && ! [[ "$CFRECORD_NAME" == *"$CFZONE_NAME" ]]; then
  CFRECORD_NAME="$CFRECORD_NAME.$CFZONE_NAME"
  echo " => Hostname is not a FQDN, assuming $CFRECORD_NAME"
fi

# Get current WAN IP
WAN_IP=$(curl -s ${WANIPSITE})

# Get zone_identifier & record_identifier
ID_FILE=.cf-id-$CFRECORD_NAME-$CFRECORD_TYPE.txt
if [ -f $ID_FILE ] && [ "$(wc -l < $ID_FILE)" -eq 4 ] \
  && [ "$(sed -n '3p' $ID_FILE)" = "$CFZONE_NAME" ] \
  && [ "$(sed -n '4p' $ID_FILE)" = "$CFRECORD_NAME" ]; then
  CFZONE_ID=$(sed -n '1p' $ID_FILE)
  CFRECORD_ID=$(sed -n '2p' $ID_FILE)
else
  echo "Updating zone_identifier & record_identifier"
  CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "Authorization: Bearer $CFAPI_TOKEN" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
  CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME&type=$CFRECORD_TYPE" -H "X-Auth-Email: $CFUSER" -H "Authorization: Bearer $CFAPI_TOKEN" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 || true)
  if [ ! -f $ID_FILE ]; then
    touch $ID_FILE
    echo "No previous ID file found, need ID update"
    # if the DNS record is not found, then create one
    if [ -z "$CFRECORD_ID" ]; then
      echo "Creating DNS record for $CFRECORD_NAME with IP $WAN_IP"
      RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records" \
        -H "X-Auth-Email: $CFUSER" \
        -H "Authorization: Bearer ${CFAPI_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$WAN_IP\", \"ttl\":$CFTTL}")
      echo "Updated successfully!"
        CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME&type=$CFRECORD_TYPE" -H "X-Auth-Email: $CFUSER" -H "Authorization: Bearer $CFAPI_TOKEN" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 || true)
    fi
  fi
  echo "$CFZONE_ID" > $ID_FILE
  echo "$CFRECORD_ID" >> $ID_FILE
  echo "$CFZONE_NAME" >> $ID_FILE
  echo "$CFRECORD_NAME" >> $ID_FILE
fi

# Retrieve the current DNS record value if it exists
if [ -n "$CFRECORD_ID" ]; then
  CURRENT_DNS_IP=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
    -H "X-Auth-Email: $CFUSER" \
    -H "Authorization: Bearer $CFAPI_TOKEN" \
    -H "Content-Type: application/json" | grep -Po '(?<="content":")[^"]*' | head -1)
else
  CURRENT_DNS_IP="127.0.0.1"
fi

# If WAN IP is unchanged and not -f flag, exit here. Else, update the DNS record
if [ "$WAN_IP" = "$CURRENT_DNS_IP" ] && [ "$FORCE" = false ]; then
  echo "WAN IP unchanged. To force update, use the -f true flag"
  exit 0
else
  # Update Cloudflare DNS record if WAN IP changed
  echo "Updating DNS to $WAN_IP"
  RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
  -H "X-Auth-Email: $CFUSER" \
  -H "Authorization: Bearer ${CFAPI_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$WAN_IP\", \"ttl\":$CFTTL}")
fi

if [[ "$RESPONSE" == *"\"success\":true"* ]]; then
  echo "Updated successfully!"
  exit 0
else
  echo "Update failed."
  echo "Response: $RESPONSE"
  exit 3
fi
