#!/bin/bash
docker run --rm \
    -v $PWD/credentials:/credentials \
    -ti prod/panorama-tls-certificate:1.0
