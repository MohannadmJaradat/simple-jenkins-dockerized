#!/bin/bash

REPO_DIR="/var/lib/jenkins/simple-jenkins-dockerized"

echo "🚀 Starting deployment..."
cd "$REPO_DIR"

echo "🛑 Stopping existing containers..."
sudo docker-compose down || true

echo "🐳 Building and starting containers..."
sudo docker-compose up -d --build --force-recreate

echo "✅ Deployment complete!"