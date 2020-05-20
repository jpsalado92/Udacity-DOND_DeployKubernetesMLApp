#!/usr/bin/env bash

# Build image and add a descriptive tag
docker build -t ml_app .

# List docker images
echo -e "Available Docker images:"
docker image ls
echo

# Run flask ML-app
docker run -p 8000:80 ml_app
