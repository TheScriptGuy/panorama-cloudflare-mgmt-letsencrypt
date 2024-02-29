FROM alpine:3.18

RUN apk update && apk add openssl certbot py3-pip curl
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN python3 -m pip install pan-python certbot-dns-cloudflare --use-pep517 && mkdir /app

COPY generate-panorama-certificate.sh /app
COPY split-certs.sh /app
COPY vars.sh /app

WORKDIR /app

CMD ["sh", "-c", "/app/generate-panorama-certificate.sh"]
