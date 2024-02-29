#!/bin/sh
# Load variables
source /app/vars.sh

# Run the certbot command to get a certificate
certbot certonly --dns-cloudflare --dns-cloudflare-credentials $CLOUDFLARE_CREDS -d $FQDN -n --agree-tos --email $EMAIL --force-renew

cd /app

# Split out all the certificates in the chain.pem file.
./split-certs.sh $FQDN

#Depending on your setup, certbot may not give you separate files for the certificate and chain.  This script expects separate files.
openssl pkcs12 -export -out letsencrypt_pkcs12.pfx -inkey /etc/letsencrypt/live/$FQDN/privkey.pem -in /etc/letsencrypt/live/$FQDN/cert.pem -passout pass:$TEMP_PWD

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