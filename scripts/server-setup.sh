#!/bin/bash

set -e

echo "Updating packages..."
apt update

echo "Installing Docker..."
apt install -y docker.io curl

echo "Starting Docker..."
systemctl enable docker
systemctl start docker

echo "Pulling Docker image..."
docker pull ${docker_image}

echo "Starting application container..."

docker run -d \
  --name scott-nginx \
  --restart unless-stopped \
  -p 80:80 \
  -e SERVER_MESSAGE="${server_message}" \
  ${docker_image}

echo "Checking Docker..."
docker ps

echo "Testing application..."
curl http://localhost