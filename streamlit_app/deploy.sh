#!/bin/bash

set -e  # Exit on error
set -o pipefail

APP_DIR="/var/lib/jenkins/simple-jenkins-dockerized/streamlit_app"
BRANCH="${1:-main}"

echo "🚀 Deploying branch: $BRANCH"

cd "$APP_DIR"

echo "🔄 Pulling latest changes..."
# git fetch origin
# git checkout "$BRANCH"
# git reset --hard "origin/$BRANCH"

echo "🐳 Building & Starting Docker container..."
docker-compose down
docker-compose up -d --build

echo "✅ App is live at: http://<your-ec2-ip>:8501/"
