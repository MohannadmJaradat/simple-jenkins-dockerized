#!/bin/bash

set -e  # Exit on error
set -o pipefail

APP_DIR="/var/lib/jenkins/simple-jenkins-dockerized/streamlit_app"
REPO_DIR="/var/lib/jenkins/simple-jenkins-dockerized"  # Renamed from GIT_DIR
BRANCH="${1:-main}"

echo "🚀 Deploying branch: $BRANCH"

cd "$REPO_DIR"

echo "🔄 Pulling latest changes..."
# Clear any GIT_DIR environment variable that might be set
unset GIT_DIR 2>/dev/null || true

# Set git config if not already set
git config user.email "jenkins@yourdomain.com" 2>/dev/null || true
git config user.name "Jenkins" 2>/dev/null || true

# Pull latest changes
git fetch origin
git checkout "$BRANCH"
git reset --hard "origin/$BRANCH"

echo "🛑 Stopping existing services..."
# Kill any running streamlit processes
sudo pkill -f streamlit || true

# Kill processes using port 8501 (more reliable than fuser)
lsof -ti:8501 | xargs kill -9 2>/dev/null || true

echo "🐳 Building & Starting Docker container..."
cd "$REPO_DIR"  # Make sure we're in the right directory for docker-compose

# Stop and remove existing containers
docker-compose down --remove-orphans 2>/dev/null || true

# Build and start new containers
docker-compose up -d --build

echo "⏳ Waiting for container to be ready..."
sleep 5

# Check if container is running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Deployment successful!"
    echo "🌐 App is live at: http://$(curl -s ifconfig.me):8501/"
    echo "🔗 Local access: http://localhost:8501/"
else
    echo "❌ Deployment failed - container is not running"
    echo "📋 Container logs:"
    docker-compose logs --tail=20
    exit 1
fi