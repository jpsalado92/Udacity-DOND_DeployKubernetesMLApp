#!/usr/bin/env bash
# This file tags and uploads an image to Docker Hub
# Assumes that an image is built via `run_docker.sh`

# Step 1:
# Authenticate
username=jpsalado92
cat token.txt | docker login --username=$username --password-stdin

# Step 2:  
# Tag
docker_image_id=05d7aaf40a32
repo=boston_housing_price
docker tag $docker_image_id $username/$repo:price_predictor

# Step 3:
# Push image to a docker repository
docker push $username/$repo
