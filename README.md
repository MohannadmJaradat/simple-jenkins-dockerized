# 🐳 Streamlit + Jenkins CI/CD Demo (Dockerized)

This project demonstrates a **dockerized CI/CD pipeline using Jenkins** to lint, test, build, and deploy a Streamlit app in Docker containers hosted on an EC2 instance. It includes GitHub integration, email notifications, and containerized deployment via Docker Compose.

---

## 📁 Project Structure

```bash
simple-jenkins-dockerized/
│
├── streamlit_app/
│   ├── app.py
│   ├── requirements.txt
│   ├── test_app.py
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── .dockerignore
│   └── streamlit.log
├── Jenkinsfile
└── README.md
```

---

## 🔧 Prerequisites

Before setting up this project, ensure you have the following installed on your EC2 instance:

### 1. Jenkins Installation
```bash
# Install Java (required for Jenkins)
sudo apt update
sudo apt install openjdk-17-jdk -y

# Add Jenkins repository and install
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 2. Docker Installation
```bash
# uninstall all conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker Compose
sudo curl -SL https://github.com/docker/compose/releases/download/v2.37.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
```

### 3. Critical: Jenkins Docker Permissions
**⚠️ Important Challenge Solved:** Jenkins needs permissions to run Docker commands without sudo.

```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins service to apply group changes
sudo systemctl restart jenkins

# Verify jenkins user can run docker commands
sudo su - jenkins
docker --version
docker-compose --version
```

---

## 🐳 Docker Configuration

To dockerize this project, several file were added, including the **Dockerfile**, which was built in a mulit-stage approach, the **docker compose** file, which orchestrates the Streamlit container with proper port mapping and restart policies, and the **dockerignore** file, which excludes unnecessary files from the Docker build context.

---

## 🚀 Manual Setup & Running the App

### 1. Fork and clone the repository

> **🔐 First time setup?** Generate and configure your SSH key:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
```
* Copy the public key and add it to your GitHub account:
   * Go to `GitHub → Settings → SSH and GPG keys → New SSH Key`
   * Paste the key and save.

* Add the private key `~/.ssh/id_ed25519` to Jenkins:
  * Navigate to `Jenkins Dashboard → Manage Jenkins → Credentials`
  * Select the `Global` domain and click `Add Credentials`
  * Choose "SSH Username with private key"
    * Username: `git` (recommended for GitHub)
    * Private Key: paste the contents of `~/.ssh/id_ed25519`
    * ID: give it a clear name like `github-ssh-key`

#### 🔍 Test SSH Connectivity to GitHub

To verify that your SSH key is correctly set up and GitHub recognizes it:

```bash
ssh -T git@github.com
```
If successful, you'll see a message like:
```bash
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

Now you're ready to fork and clone the repo:
1. Fork the original repository to your own GitHub account.
2. clone **your fork** using SSH:
```bash
git clone git@github.com:<your-username>/simple_jenkins.git
cd simple_jenkins/streamlit_app
```

### 2. Running with Docker

#### Option A: Using Docker Compose (Recommended)
```bash
# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

#### Option B: Using Docker directly
```bash
# Build the image
docker build -t streamlit-app .

# Run the container
docker run -d -p 8501:8501 --name streamlit_app streamlit-app

# View logs
docker logs streamlit_app

# Stop the container
docker stop streamlit_app
docker rm streamlit_app
```

### 3. Access the App

Once the container is running, open your browser and navigate to:
```
http://<your-ec2-public-ip>:8501
```

---

## 🛠️ Systemd Service for Docker Compose

The systemd service has been updated to manage the Docker containerized application:

### 📄 Updated Unit File

```bash
sudo nano /etc/systemd/system/streamlit-app.service
```

```ini
[Unit]
Description=Streamlit Docker App Service
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/var/lib/jenkins/simple-jenkins-dockerized/streamlit_app
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down

[Install]
WantedBy=multi-user.target
```

### 🚀 Enable and Start the Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable streamlit-app
sudo systemctl start streamlit-app
sudo systemctl status streamlit-app
```

---

## 🤖 Jenkins CI/CD Pipeline (Dockerized)

### ✅ Key Features

* Pulls code from GitHub
* Lints `app.py` using Docker containers
* Runs unit tests in isolated Docker environments
* Builds Docker images with Docker Compose
* Manages container lifecycle (stop, build, start)
* Sends email notifications on build events
* Triggers automatically on GitHub push

### 🔄 Pipeline Flow

| Stage          | Description                                           | Docker Usage                                    |
| -------------- | ----------------------------------------------------- | ----------------------------------------------- |
| Checkout       | Clones the repository to Jenkins workspace           | N/A                                             |
| Lint           | Runs flake8 linting                                   | `docker run python:3.11` container             |
| Test           | Executes pytest unit tests                           | `docker run python:3.11` container             |
| Build & Deploy | Builds Docker image and deploys with docker-compose  | `docker-compose build` + `docker-compose up`   |
| Archive        | Creates deployment archive                            | N/A                                             |

### 🧩 Jenkinsfile Evolution & Pipeline Breakdown

#### Initial Pipeline Structure (v1)
The original pipeline had separate stages with individual deploy script:

| Stage     | Description                                    | Issues Identified                               |
| --------- | ---------------------------------------------- | ----------------------------------------------- |
| Pull Repo | Clones repository to specific location         | Used `GIT_DIR` which conflicted with Git       |
| Lint      | Runs flake8 in temporary Docker container     | File path issues with artifact copying         |
| Build     | Builds Docker image with docker-compose       | Separate from deploy, causing context issues   |
| Test      | Runs pytest in temporary Docker container     | File path issues with artifact copying         |
| Deploy    | Executes separate `deploy.sh` script          | Different context from build stage             |

#### Refactored Pipeline Structure (v2)
The improved version addresses the issues:

```groovy
// Combined Build & Deploy stage eliminates context confusion
stage("Build & Deploy") {
    steps {
        timeout(time: 10, unit: 'MINUTES') {
            sh '''
                sudo docker-compose down --remove-orphans || true
                sudo docker system prune -f || true
                sudo docker-compose build --no-cache --pull
                sudo docker-compose up -d
                
                # Verification step
                if sudo docker-compose ps | grep -q "Up"; then
                    echo "✅ Deployment successful!"
                else
                    echo "❌ Container failed to start"
                    sudo docker-compose logs --tail=20
                    exit 1
                fi
            '''
        }
    }
}
```

#### Key Improvements Made:

1. **Environment Variable Fix**: Renamed `GIT_DIR` to `WORKSPACE_DIR` to avoid Git conflicts
2. **Combined Build & Deploy**: Eliminated separate deploy script context issues  
3. **Better Error Handling**: Added container verification and logging
4. **Cache Management**: Force pull latest base images with `--no-cache --pull`
5. **Proper Artifact Handling**: Fixed file path issues in lint and test stages

---

## 🚨 Challenges Faced & Solutions

### 1. **Jenkins Docker Permissions Issue**
**Problem:** Jenkins couldn't run Docker commands due to permission restrictions.
```bash
# Error: permission denied while trying to connect to Docker daemon
```

**Solution:** Added jenkins user to docker group and restarted Jenkins service:
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### 2. **GIT_DIR Environment Variable Conflict** ⚠️
**Problem:** The `GIT_DIR` environment variable was conflicting with Git operations in Jenkins, causing repository access issues.
```bash
# Error: Not a git repository
# Error: fatal: not a git repository (or any of the parent directories): .git
```

**Solution:** Renamed the environment variable from `GIT_DIR` to `WORKSPACE_DIR`:
```groovy
environment {
    WORKSPACE_DIR = '/var/lib/jenkins/simple-jenkins-dockerized'  // Renamed from GIT_DIR
    // ...
}
```

### 3. **Build vs Deploy Context Confusion**
**Problem:** The original pipeline had separate Build and Deploy stages running from different contexts, causing Docker build inconsistencies.

**Initial Approach (Problematic):**
```groovy
stage("Build") {
    // Built Docker image in one context
    sh 'docker-compose build'
}
stage("Deploy") {
    // Ran deploy.sh script in different context
    sh 'bash ${APP_DIR}/deploy.sh'
}
```

**Solution:** Combined Build & Deploy into a single stage with consistent context:
```groovy
stage("Build & Deploy") {
    steps {
        dir("${APP_DIR}") {
            sh '''
                sudo docker-compose down --remove-orphans || true
                sudo docker-compose build --no-cache --pull
                sudo docker-compose up -d
            '''
        }
    }
}
```

### 4. **Artifact Path Issues**
**Problem:** In the original pipeline, artifact files weren't being found due to path inconsistencies:
```bash
# Original problematic approach
sh 'cp /var/lib/jenkins/simple-jenkins-dockerized/streamlit_app/lint_report.txt lint_report.txt'
archiveArtifacts artifacts: '**/lint_report.txt'
```

**Solution:** Used proper `dir()` blocks and relative paths:
```groovy
dir("${APP_DIR}") {
    sh '''
        docker run --rm -v $(pwd):/app python:3.11 \
            bash -c "pip install flake8 && flake8 /app/app.py" \
            | tee lint_report.txt || true
    '''
    archiveArtifacts artifacts: 'lint_report.txt', allowEmptyArchive: true
}
```

### 5. **Container Persistence After Jenkins Build**
**Problem:** Docker containers would stop when Jenkins build finished.

**Solution:** Used `docker-compose up -d` (detached mode) and proper systemd service integration to ensure containers persist independently of Jenkins builds.

---

## 🔌 GitHub Webhook Setup

Same as before - configure webhook to trigger on push events:

1. Navigate to your GitHub repo → **Settings > Webhooks**
2. **Payload URL**: `http://<JENKINS_PUBLIC_IP>:8080/github-webhook/`
3. **Content type**: `application/json`
4. **Event**: Just the push event

---

## 📧 Email Notifications

Email notifications remain configured for:
* ✅ Success
* ❌ Failure  
* ⚠️ Unstable
* 🔁 State Change
* 🔧 Fixed
* 📦 Always (post actions)

---

## 🔒 Security Considerations

* Jenkins user has Docker group permissions (required for container management)
* All containers run as non-root users where possible
* Docker daemon socket is protected by group permissions
* Container images are built from official Python base images

---

## 🎯 Benefits of Dockerization

* **Consistency:** Same environment across development, testing, and production
* **Isolation:** Each stage runs in its own container
* **Scalability:** Easy to scale horizontally with Docker Compose
* **Dependency Management:** All dependencies are containerized
* **Quick Rollbacks:** Easy to revert to previous container versions
* **Resource Efficiency:** Containers share the host OS kernel

---

## ✅ Final Notes

* Ensure **port 8501** is open in the EC2 security group
* Monitor Docker resource usage: `docker stats`
* Clean up unused containers periodically: `docker system prune`
* Container logs are available via: `docker-compose logs`
* Consider future enhancements:
  * Multi-stage Docker builds for smaller images
  * Container orchestration with Kubernetes
  * Docker registry integration for image versioning
  * Health checks and monitoring with Prometheus

---

## 🛠️ Troubleshooting

### Common Issues:

1. **Container won't start:**
   ```bash
   docker-compose logs streamlit
   ```

2. **Permission errors:**
   ```bash
   # Check if jenkins user is in docker group
   groups jenkins
   ```

3. **Port already in use:**
   ```bash
   sudo docker-compose down
   sudo netstat -tulpn | grep 8501
   ```

4. **Build failures:**
   ```bash
   # Clean everything and rebuild
   sudo docker system prune -a
   sudo docker-compose build --no-cache
   ```
---

## 🎯 **Conclusion**

This project demonstrates the evolution from a traditional Jenkins CI/CD pipeline to a fully dockerized, production-ready deployment system. The journey highlighted several critical lessons that transformed a fragile, cache-dependent pipeline into a robust, deterministic deployment process.

### **🔑 Key Insights Learned:**

#### **1. Context is King**
The most significant breakthrough was realizing that **build and deploy are not separate concerns** - they're part of the same atomic operation that should happen in the same execution context. Splitting them across different stages created inconsistencies that manifested as "phantom deployments" where builds succeeded but changes weren't reflected.

#### **2. Cache is the Enemy in CI/CD**
Docker's caching mechanism, while beneficial for development, becomes a liability in automated pipelines. The solution was implementing aggressive cache-busting strategies:
- `--no-cache --pull` flags force fresh builds every time
- `docker system prune -f` eliminates stale artifacts
- Assumption: **cache is always stale** in production pipelines

#### **3. Simplicity Wins**
Eliminating the separate `deploy.sh` script reduced complexity and failure points. The refactored pipeline has:
- **Fewer moving parts** → Lower failure probability
- **Single source of truth** → Easier debugging
- **Unified execution context** → Consistent behavior

#### **4. Environment Variables Matter**
Naming conflicts like `GIT_DIR` can cause subtle, hard-to-debug issues. Always research system-reserved variable names before using them in your pipeline.

### **🚀 Pipeline Evolution Summary:**

| Aspect | Before (v1) | After (v2) | Impact |
|--------|-------------|------------|---------|
| **Context** | Split Build/Deploy stages | Unified Build & Deploy | ✅ Eliminates context confusion |
| **Caching** | Relied on Docker cache | Aggressive cache busting | ✅ Guarantees fresh deployments |
| **Scripts** | External `deploy.sh` | Integrated pipeline logic | ✅ Reduces complexity |
| **Artifacts** | Absolute path copying | Relative paths with `dir()` | ✅ Consistent file handling |
| **Reliability** | Intermittent cache issues | Deterministic builds | ✅ Production-ready |

### **🎓 Best Practices Established:**

1. **Keep Related Operations Together**: Build and deploy should be atomic
2. **Assume Cache is Stale**: Always use `--no-cache` in CI/CD
3. **Verify Everything**: Include health checks and container status verification
4. **Use Proper Directory Context**: Leverage Jenkins `dir()` blocks for consistency
5. **Minimize External Dependencies**: Fewer scripts = fewer failure points

### **🔮 Future Enhancements:**

This foundation enables several advanced capabilities:
- **Blue-Green Deployments**: Zero-downtime updates with multiple container instances
- **Multi-Environment Pipelines**: Extend to staging/production with environment-specific configs
- **Kubernetes Migration**: Container-ready architecture simplifies orchestration adoption
- **Monitoring Integration**: Add health checks, metrics, and alerting
- **Security Hardening**: Implement container scanning and vulnerability assessments

### **💡 Final Thoughts:**

The transformation from a traditional deployment to a dockerized CI/CD pipeline wasn't just about adopting new technology - it was about **understanding the fundamental principles** of reliable automation. The challenges we faced and solved - permission issues, environment conflicts, cache problems, and context confusion - are common pitfalls that many teams encounter.

**The real value** lies not in the specific tools used, but in the **systematic approach to problem-solving**: identifying root causes, implementing incremental fixes, and continuously refining the process. This methodology applies whether you're working with Jenkins and Docker, GitHub Actions and Kubernetes, or any other CI/CD stack.

By documenting both the failures and solutions, this project becomes a reference for future implementations and a testament to the iterative nature of DevOps engineering. **Every challenge was an opportunity to build a more robust system** - and that's the essence of continuous improvement in DevOps culture.

---