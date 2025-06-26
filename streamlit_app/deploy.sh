#!/bin/bash

set -e  # Exit on error
set -o pipefail

APP_DIR="/var/lib/jenkins/simple-jenkins-dockerized/streamlit_app"
BRANCH="${1:-main}"

echo "🚀 Deploying branch: $BRANCH"

cd "$APP_DIR"

# echo "🔄 Pulling latest changes..."
# git fetch origin
# git checkout "$BRANCH"
# git reset --hard "origin/$BRANCH"

# Check if port 8501 is in use and kill the process using it
echo "🛑 Checking if port 8501 is in use..."

PORT_IN_USE=$(lsof -ti:8501)
if [ -n "$PORT_IN_USE" ]; then
  echo "⚠️ Port 8501 is in use by PID(s): $PORT_IN_USE. Terminating them..."
  kill -9 $PORT_IN_USE || true
else
  echo "✅ Port 8501 is free."
fi

echo "🐳 Building & Starting Docker container..."
docker-compose down
docker-compose up -d --build

echo "✅ App is live at: http://<your-ec2-ip>:8501/"
