#!/bin/bash

set -e  # Exit on error
set -o pipefail

APP_BASE="/home/ubuntu"
REPO_URL="git@github.com:MohannadmJaradat/simple-jenkins-dockerized.git"
BRANCH="${1:-main}"  # Use first arg or default to 'main'

APP_DIR="$APP_BASE/simple-jenkins-dockerized/streamlit_app"

echo "🚀 Deploying branch: $BRANCH"

# Clone repo if not present
if [ ! -d "$APP_BASE/simple-jenkins-dockerized/.git" ]; then
    echo "📦 Cloning repository..."
    git clone -b "$BRANCH" "$REPO_URL" "$APP_BASE/simple-jenkins-dockerized"
else
    echo "🔄 Pulling latest changes..."
    cd "$APP_BASE/simple-jenkins-dockerized"
    git fetch origin
    git checkout "$BRANCH"
    git reset --hard "origin/$BRANCH"
fi

# Go to app directory
cd "$APP_DIR"

# Set up Python environment
echo "🐍 Setting up Python environment..."
python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Restart Streamlit
echo "🚦 Restarting Streamlit app..."
pkill streamlit || true
fuser -k 8501/tcp || true
sudo systemctl restart streamlit-app
# nohup bash -c "source venv/bin/activate && streamlit run app.py \
#     --server.port 8501 \
#     --server.address 0.0.0.0 \
#     --server.headless true \
#     --server.enableCORS false" > streamlit.log 2>&1 &

echo "✅ Deployment finished! App running at: http://34.229.206.198:8501/"