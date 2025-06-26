#!/bin/bash

set -e  # Exit on error
set -o pipefail

APP_DIR="/var/lib/jenkins/simple-jenkins-dockerized/streamlit_app"
GIT_DIR="/var/lib/jenkins/simple-jenkins-dockerized"
BRANCH="${1:-main}"

echo "🚀 Deploying branch: $BRANCH"

cd "$GIT_DIR"

echo "🔄 Pulling latest changes..."
git fetch origin
git checkout "$BRANCH"
git reset --hard "origin/$BRANCH"

# Check if port 8501 is in use and kill the process using it
echo "🛑 Checking if port 8501 is in use..."

pkill streamlit || true
fuser -k 8501/tcp || true

echo "🐳 Building & Starting Docker container..."
docker-compose down
docker-compose up -d --build

echo "✅ App is live at: http://<your-ec2-ip>:8501/"
