#!/usr/bin/env bash

# Account ID to write zone to
ACCOUNT_ID=""

# Apex CNAME value
APEX_CNAME=""

# Check if we have our dependecies
if ! command -v basename &> /dev/null; then
  echo "Dependency missing: \"basename\" missing"
  exit 1
fi

if ! command -v curl &> /dev/null; then
  echo "Dependency missing: \"curl\" missing"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Dependency missing: \"jq\" missing"
  exit 1
fi

if ! command -v sed &> /dev/null; then
  echo "Dependency missing: \"sed\" missing"
  exit 1
fi

# Import zones
echo "Looping through files in zones/"
echo "---------------"
for ZONE in zones/*
do
  echo "Processing $ZONE"
  DOMAIN=$(basename -s .txt $ZONE)
  echo "Attempting to create $DOMAIN in Cloudflare"
  RESULT_CREATE=$(curl -s -X POST -H "X-Auth-Key: $CF_API_KEY" -H "X-Auth-Email: $CF_API_EMAIL" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones" \
    --data '{"name":"'$DOMAIN'","account":{"id":"'$ACCOUNT_ID'"},"jump_start":false}' 2> /dev/null)
  
  echo "Result:"
  echo $RESULT_CREATE

  # Extract ZONE ID from response
  ZONE_ID=$(echo $RESULT_CREATE | jq .result.id)
  ZONE_ID=${ZONE_ID//\"}
  
  # Display info on action
  echo "Uploading $ZONE to $DOMAIN with ID $ZONE_ID in account $ACCOUNT_ID"

  # Create temp file without NS records
  sed '/IN\tNS/d' $ZONE > zone.temp

  RESULT_UPLOAD=$(curl -X POST -H "X-Auth-Key: $CF_API_KEY" -H "X-Auth-Email: $CF_API_EMAIL" \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/import" \
    --form "file=@zone.temp;proxied=false" 2> /dev/null)

  echo "Result:"
  echo $RESULT_UPLOAD

  # Remove temp file
  rm zone.temp

  # Create apex CNAME
  if ! [ -z "$APEX_CNAME" ]; then
    echo "Adding $APEX_CNAME as apex CNAME."
    RESULT_APEX=$(curl -X POST -H "X-Auth-Key: $CF_API_KEY" -H "X-Auth-Email: $CF_API_EMAIL" \
      -H "Content-Type: application/json" \
      "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
      --data '{"type":"CNAME","name":"'$DOMAIN'","content":"'$APEX_CNAME'","ttl":1,"proxied":false}' 2> /dev/null)
    
    echo "Result:"
    echo $RESULT_APEX
  fi
done
