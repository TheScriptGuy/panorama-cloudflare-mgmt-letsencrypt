# Panorama Management Certificate & LetsEncrypt :lock: & Cloudflare :cloud:

Step right up! Step right up!

Looking to update your Panorama Management Certificate with Let's Encrypt? Look no further!

The idea behind this repository is to help with automating the renewal of the management certificate of your Palo Alto Networks Panorama device. At a high level:
1. Adds temporary DNS TXT records to your Cloudflare domain.
2. Attempts to enroll a certificate through Let's Encrypt
3. Uploads the certificate chain to the Panorama device.
4. Uploads that new certificate to the Panorama device. 
5. Commits the changes (which forces the management services to restart)

## Requirements
### Cloudflare :cloud:
* API key for your custom domain that will allow us to create DNS TXT records
* An 'A' record that already points to your Panorama instance.

### Panorama
* An API Key used by curl to upload the Let's Encrypt Certificate and private key to Panorama (stored in `panrc_panxapi`)
* A base64 encoded username:password value (stored in `panrc_curl`)

### Docker :whale:
* The ability to run docker on your host.

### Cron :time:
* For automated renewal of certificates (they're only valid for 3 months), leverage a cron job to schedule automated renewal. To help with the scheduling syntax within cron, refer to [crontab.guru](https://crontab.guru/).

# Installation :wrench:

## Cloudflare :cloud:
API Token Generation instructions are [here](https://github.com/TheScriptGuy/panorama-cloudflare-mgmt-letsencrypt/blob/493cf8f4661562c0e9435ced076355a1faf4d5f6/cloudflare-token-instructions.md)

## Github
First clone the github repository:
```bash
$ git clone https://github.com/TheScriptGuy/panorama-cloudflare-mgmt-letsencrypt
...
$ cd panorama-cloudflare-mgmt-letsencrypt
$ ./setup.sh
```

## Running `setup.sh`
By running the `setup.sh` file, it'll prompt you for the following information:
1. Management IP address/hostname
2. FQDN to be used in the Let's Encrypt Certificate
3. Email address for the Let's Encrypt certificate renewal process.
4. Cloudflare API Token.
5. Username/password to connect to Panorama with.

After this information is entered:
1. The `vars.sh` file is updated with the information provided.
2. The Cloudflare API token is added to `credentials/cloudflare.ini`.
3. A base64 encoded username:password pair is added to `credentials/panrc_curl` file
4. An [API key](https://docs.paloaltonetworks.com/pan-os/11-0/pan-os-panorama-api/get-started-with-the-pan-os-xml-api/get-your-api-key) that was generated from Panorama when entering the username:password pair is added to `credentials/panrc_panxapi` file.

## Docker :whale:
### Building the image
Leverage the `build-image.sh` script to help build the image for you.

### Create a container based off the image
Run the `run.sh` script to run the container. This will:
1. Generate the certificates from Let's Encrypt by creating appropriate TXT records in Cloudflare to validate you own the domain.
2. Upload the subordinate Certificate Authorities to Panorama.
3. Upload the Lets Encrypt private key and certificate to Panorama.
4. Update the `$PANORAMA_PROFILE` object to reference this newly uploaded certificate.
5. Commit changes to Panorama <-- at this point, Panorama Management services will restart. It will output an error that the API call was problematic. Just wait for the services to restart before connecting.

## :zap: Important to note :zap:
Let's encrypt has API limits and will only allow you to generate a limited amount of certificates for a single hostname in a small window. If you reach the limit, unfortunately you just have to wait for the window to lapse before trying again.

