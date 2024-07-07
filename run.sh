#!/bin/bash

PANTLSDIR=/projects/github/palo-alto-networks/panorama-letsencrypt

cd PANTLSDIR

docker run --rm \
    -v $PWD/credentials:/credentials \
    prod/panorama-tls-certificate:1.0
