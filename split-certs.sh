#!/bin/sh

# Create a temporary directory to hold individual certs
mkdir -p certs
cd certs

# Split the chain.pem into individual certificates using awk
awk 'BEGIN {c=0;} /-----BEGIN CERTIFICATE-----/ {c++} {print > "cert" c ".pem"}' /etc/letsencrypt/live/$1/chain.pem

# Initialize subordinate CA counter
sub_ca_counter=1

# Loop through the extracted certs
for cert_file in cert*.pem; do
    # Check if the certificate has the "CA Issuers - URI" field
    if openssl x509 -in "$cert_file" -noout -text | grep "CA Issuers - URI" > /dev/null; then
        # Likely a Subordinate CA
        mv "$cert_file" "../subca${sub_ca_counter}.pem"
        sub_ca_counter=$((sub_ca_counter + 1))
    else
        # Likely a Root CA, but ensure only one rootca.pem is created
        if [ ! -f ../rootca.pem ]; then
            mv "$cert_file" ../rootca.pem
        else
            # If another root is found, treat it as a subordinate to maintain uniqueness of rootca.pem
            mv "$cert_file" "../subca${sub_ca_counter}.pem"
            sub_ca_counter=$((sub_ca_counter + 1))
        fi
    fi
done

# Clean up
cd ..
rm -r certs
