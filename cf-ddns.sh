#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Automatically update your CloudFlare DNS record to the IP, Dynamic DNS

# Default config
CFKEY=""
CFAPI_TOKEN=""
Authorization=""
CFUSER=""
CFZONE_NAME=""
CFRECORD_NAME=""

CFTTL=120
FORCE=false

CFRECORD_TYPE=""
WANIPSITE=""

# Get parameter
while getopts 46k:u:h:z:a:f: opts; do
  case ${opts} in
    4) CFRECORD_TYPE="A"; WANIPSITE="http://ipv4.icanhazip.com" ;;
    6) CFRECORD_TYPE="AAAA"; WANIPSITE="http://ipv6.icanhazip.com" ;;
    k) CFKEY=${OPTARG} ;;
    u) CFUSER=${OPTARG} ;;
    h) CFRECORD_NAME=${OPTARG} ;;
    z) CFZONE_NAME=${OPTARG} ;;
    a) CFAPI_TOKEN=${OPTARG} ;;
    f) FORCE=${OPTARG} ;;
    *) echo "Invalid option: -${OPTARG}" >&2; exit 1 ;;
  esac
done

# Validate required settings
if [ -z "$CFRECORD_TYPE" ]; then
  echo "You must specify either -4 for IPv4 or -6 for IPv6."
  exit 2
fi

if [ -z "$CFKEY" ] && [ -z "$CFAPI_TOKEN" ]; then
  echo "Missing API key or token. Obtain it from https://www.cloudflare.com/a/account/my-account"
  exit 2
elif [ -n "$CFKEY" ] && [ -n "$CFAPI_TOKEN" ]; then
  echo "Only one of API key or token should be provided."
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

# Set authorization header
if [ -n "$CFKEY" ]; then
  Authorization="X-Auth-Key: ${CFKEY}"
else
  Authorization="Authorization: Bearer ${CFAPI_TOKEN}"
fi

# Ensure the hostname is a fully qualified domain name (FQDN)
if [ "$CFRECORD_NAME" != "$CFZONE_NAME" ] && ! [[ "$CFRECORD_NAME" == *"$CFZONE_NAME" ]]; then
  CFRECORD_NAME="$CFRECORD_NAME.$CFZONE_NAME"
  echo " => Hostname is not a FQDN, assuming $CFRECORD_NAME"
fi

# Get current and old WAN IP
WAN_IP=$(curl -s ${WANIPSITE})
WAN_IP_FILE=./.cf-wan_ip_$CFRECORD_NAME.txt
OLD_WAN_IP=""
if [ -f $WAN_IP_FILE ]; then
  OLD_WAN_IP=$(cat $WAN_IP_FILE)
else
  echo "No previous IP file found, need IP update"
fi

# If WAN IP is unchanged and not -f flag, exit here
if [ "$WAN_IP" = "$OLD_WAN_IP" ] && [ "$FORCE" = false ]; then
  echo "WAN IP unchanged. To force update, use the -f true flag"
  exit 0
fi

# Get zone_identifier & record_identifier
ID_FILE=./.cf-id_$CFRECORD_NAME.txt
if [ -f $ID_FILE ] && [ "$(wc -l < $ID_FILE)" -eq 4 ] \
  && [ "$(sed -n '3p' $ID_FILE)" = "$CFZONE_NAME" ] \
  && [ "$(sed -n '4p' $ID_FILE)" = "$CFRECORD_NAME" ]; then
    CFZONE_ID=$(sed -n '1p' $ID_FILE)
    CFRECORD_ID=$(sed -n '2p' $ID_FILE)
else
    echo "Updating zone_identifier & record_identifier"
    CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "$Authorization" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
    CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "$Authorization" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
    echo "$CFZONE_ID" > $ID_FILE
    echo "$CFRECORD_ID" >> $ID_FILE
    echo "$CFZONE_NAME" >> $ID_FILE
    echo "$CFRECORD_NAME" >> $ID_FILE
fi

# Update Cloudflare DNS record if WAN IP changed
echo "Updating DNS to $WAN_IP"
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
  -H "X-Auth-Email: $CFUSER" \
  -H "$Authorization" \
  -H "Content-Type: application/json" \
  --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$WAN_IP\", \"ttl\":$CFTTL}")

if [[ "$RESPONSE" == *"\"success\":true"* ]]; then
  echo "Updated successfully!"
  echo $WAN_IP > $WAN_IP_FILE
else
  echo "Update failed."
  echo "Response: $RESPONSE"
  exit 1
fi
