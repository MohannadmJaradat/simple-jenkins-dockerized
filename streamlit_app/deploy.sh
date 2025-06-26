#!/bin/bash

REPO_DIR="/var/lib/jenkins/simple-jenkins-dockerized"

echo "🚀 Starting deployment..."
cd "$REPO_DIR"

echo "🛑 Stopping existing containers..."
sudo docker-compose down --remove-orphans || true

echo "🐳 Building and starting containers..."
sudo docker system prune -f
sudo docker-compose build --no-cache
sudo docker-compose up -d

echo "✅ Deployment complete!"