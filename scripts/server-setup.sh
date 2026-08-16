#!/bin/bash
set -e

echo "Updating packages..."
apt update -y

echo "Installing Docker..."
apt install -y docker.io curl

echo "Starting Docker..."
systemctl enable docker
systemctl start docker

echo "Pulling Docker image..."
docker pull scottobiaya/scott-nginx-app:2.1

echo "Starting application container..."
docker run -d \
  --name scott-nginx \
  --restart unless-stopped \
  -p 80:80 \
  -e SERVER_MESSAGE="${SERVER_MESSAGE}" \
  scottobiaya/scott-nginx-app:2.1

echo "Checking Docker..."
docker ps

echo "Testing application..."
curl http://localhost