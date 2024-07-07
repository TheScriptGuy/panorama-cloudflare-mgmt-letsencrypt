#!/bin/sh
# Last Updated:         2024/02/29
# Version:              0.01
# Description:          Downloads and updates the Let's Encrypt certificate on Panorama.
# Author:               TheScriptGuy (https://github.com/TheScriptGuy)

# Load variables
echo "Loading variables..."
source /app/vars.sh
echo "Loading variables done."

# Run the certbot command to get a certificate
echo "Certificate enrollment starting with Let's Encrypt"
certbot certonly --dns-cloudflare-propagation-seconds 30 --dns-cloudflare --dns-cloudflare-credentials $CLOUDFLARE_CREDS -d $FQDN -n --agree-tos --email $EMAIL --force-renew

# Check to see if the private key and certificate files exist.
privkey_path="/etc/letsencrypt/live/$FQDN/privkey.pem"
cert_path="/etc/letsencrypt/live/$FQDN/cert.pem"

if [ ! -f "$privkey_path" ] || [ ! -f "$cert_path" ]; then
    echo "Required files do not exist:"
    [ ! -f "$privkey_path" ] && echo "$privkey_path is missing."
    [ ! -f "$cert_path" ] && echo "$cert_path is missing."
    exit 1
else
    echo "Certificate enrollment successful."
    
    # Split out all the certificates in the chain.pem file.
    ./split-certs.sh $FQDN

    #Depending on your setup, certbot may not give you separate files for the certificate and chain.  This script expects separate files.
    echo "Creating the pkcs12 file from $privkey_path and $cert_path"
    openssl pkcs12 -export -out letsencrypt_pkcs12.pfx -inkey /etc/letsencrypt/live/$FQDN/privkey.pem -in /etc/letsencrypt/live/$FQDN/cert.pem -passout pass:$TEMP_PWD
    if [ $? -eq 0 ]; then
        echo "File letsencrypt_pkcs12.pfx has been created."
    else
        exit 1
    fi
fi

cd /app

if [ -f "letsencrypt_pkcs12.pfx" ]; then

    for cert in subca*.pem; do
        # Check if the glob gets expanded to existing files.
        # If not, cert will be exactly "subca*.pem" (this depends on shell options).
        if [ -e "$cert" ]; then
            # Your command here, e.g., echo or openssl command
            obj_cert=$(openssl x509 -in $cert -noout -subject | sed 's/subject=//' | tr -d '[:punct:]' | tr -d ' ' | tr '[:upper:]' '[:lower:]')

            echo "Processing $cert and uploading to object $obj_cert"
            # Example of an OpenSSL command: print certificate details
            curl -k --form file=@$cert "https://$PAN_MGMT/api/?type=import&category=certificate&certificate-name=$obj_cert&format=pem" -H "$API_KEY_CURL" && echo " "
        else
            echo "No subca*.pem files found."
            exit
        fi
    done

    rm -v subca*.pem

    # Now we upload the letsencrypt certificate
    curl -k --form file=@letsencrypt_pkcs12.pfx "https://$PAN_MGMT/api/?type=import&category=certificate&certificate-name=$CERT_NAME&format=pkcs12&passphrase=$TEMP_PWD" -H "$API_KEY_CURL" && echo " "
    curl -k --form file=@letsencrypt_pkcs12.pfx "https://$PAN_MGMT/api/?type=import&category=private-key&certificate-name=$CERT_NAME&format=pkcs12&passphrase=$TEMP_PWD" -H "$API_KEY_CURL" && echo " "

    rm letsencrypt_pkcs12.pfx

    # Set the certificate profile name
    panxapi.py -h $PAN_MGMT -K "$API_KEY_PANXAPI" -S "<certificate>$CERT_NAME</certificate>" "/config/panorama/ssl-tls-service-profile/entry[@name='$PANORAMA_PROFILE']"

    panxapi.py -h $PAN_MGMT -K "$API_KEY_PANXAPI" -C '' --sync

fi
