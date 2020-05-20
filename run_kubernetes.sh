#!/usr/bin/env bash

# Step 1:
# Authenticate
username=<USERNAME>
cat token.txt | docker login --username=$username --password-stdin

# Step 2
# Run the Docker Hub container with kubernetes
repo=<REPO_NAME>:<TAG>
app_name=mlapp
kubectl run $app_name\
    --image=$username/$repo\
    --port=80 --labels app=$app_name

# Step 3:
# List kubernetes pods
kubectl get pods

# Step 4:
# Forward the container port to a host
kubectl port-forward $app_name 8000:80
kubectl describe pod $app_name