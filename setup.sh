#!/bin/bash

# Collect inputs
echo "Enter Email Address for Let's Encrypt Certificate:"
read EMAIL

echo "Enter hostname for panorama management:"
read PAN_MGMT

echo "Enter hostname for certificate:"
read FQDN

echo "Enter Cloudflare API key:"
read CLOUDFLARE_CREDS

echo "Enter Username:"
read USERNAME

echo "Enter Password (input will be hidden):"
read -s PASSWORD

# Validate inputs (simple validation)
if [ -z "$EMAIL" ] || [ -z "$PAN_MGMT" ] || [ -z "$FQDN" ] || [ -z "$CLOUDFLARE_CREDS" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "All fields are required."
    exit 1
fi

# Replace values in vars.sh.template and output to vars.sh
sed "s/<hostname to connect to>/$PAN_MGMT/g; s/<hostname that is in the cert - probably same as \$PAN_MGMT>/$FQDN/g; s/<certbot email address>/$EMAIL/g" vars.sh.template > vars.sh

# Write Cloudflare credentials to cloudflare.ini
echo "dns_cloudflare_api_token = $CLOUDFLARE_CREDS" > credentials/cloudflare.ini

# Create panrc_curl file with base64 encoded username:password
echo "Authorization: Basic $(echo -n "$USERNAME:$PASSWORD" | base64)" > credentials/panrc_curl

echo "Setup complete."

