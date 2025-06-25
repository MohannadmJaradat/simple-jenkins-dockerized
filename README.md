# 🧪 Streamlit + Jenkins CI/CD Demo

This project demonstrates a **CI/CD pipeline using Jenkins** to lint, test, build, and deploy a simple Streamlit app hosted on an EC2 instance. It includes GitHub integration, email notifications, and deployment via `systemd`.

---

## 📁 Project Structure

```bash
simple_jenkins/
│
├── streamlit_app/
│   ├── app.py
│   ├── requirements.txt
│   ├── test_app.py
│   ├── deploy.sh
│   └── streamlit.log
├── Jenkinsfile
└── README.md
```

---
### ################################# add prerequisites secion, they are installing jenkins and installing docker.


## 🚀 Manual Setup & Running the App

### Note that you must switch to "jenkins" user, which is the user used when a jenkins run is triggered.

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

### 2. Create and activate a virtual environment

```bash
python3 -m venv venv
. venv/bin/activate
```

### 3. Install dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Run the Streamlit app

To start the Streamlit app manually, use the following command:

```bash
streamlit run app.py --server.port 8501 --server.address 0.0.0.0 --server.headless true
```

### 🔍 Explanation of Flags:
- `--server.port 8501`: Specifies the port number (default: 8501).
- `--server.address 0.0.0.0`: Binds the app to all interfaces (public access).
- `--server.headless true`: Enables headless mode (ideal for servers).

### 5. Access the app

Once the app is running, open your browser and navigate to:

```
http://<your-ec2-public-ip>:8501
```

---

## 🛠️ Running as a Systemd Service

When the Streamlit app is run directly through a Jenkins pipeline, it **terminates as soon as the Jenkins build finishes**. To keep the app running in the background **independently of Jenkins**, we use a `systemd` service.

This ensures that the app:

- ✅ Stays running after the Jenkins job ends
- ✅ Automatically restarts on crash or system reboot
- ✅ Runs as a background service under the `jenkins` user

---

### 📄 Create a Unit File

```bash
sudo nano /etc/systemd/system/streamlit-app.service
```

Paste the following:

```ini
[Unit]
Description=Streamlit App Service
After=network.target

[Service]
User=jenkins
WorkingDirectory=/srv/streamlit_app/simple_jenkins/streamlit_app
ExecStart=/srv/streamlit_app/simple_jenkins/streamlit_app/venv/bin/streamlit run app.py --server.port 8501 --server.address 0.0.0.0 --server.headless true
Restart=always
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

### Make sure to give ownership to jenkins user:
```bash
sudo chown jenkins:jenkins /etc/systemd/system/streamlit-app.service
```

### 🚀 Enable and Start the Service

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable streamlit-app
sudo systemctl start streamlit-app
sudo systemctl status streamlit-app
```

Your app will:

* ✅ Start on boot
* ✅ Restart if it crashes
* ✅ Run under the `jenkins` user

---

## 🤖 Jenkins CI/CD Pipeline

### ✅ Key Features

* Pulls code from GitHub
* Lints `app.py` using `flake8`
* Runs unit tests with `pytest`
* Builds `.tar.gz` archive of the app
* Deploys via `deploy.sh` and `systemd`
* Sends email notifications on build events
* Triggers automatically on GitHub push

---

## 🔌 GitHub Webhook Setup

1. Navigate to your GitHub repo → **Settings > Webhooks**
2. Click **Add webhook**

   * **Payload URL**: `http://<JENKINS_PUBLIC_IP>:8080/github-webhook/`
   * **Content type**: `application/json`
   * **Event**: Just the push event

### Jenkins Configuration

* ✅ Enable GitHub project
* ✅ Check "Build when a change is pushed to GitHub"

---

## 📧 Email Notifications

Emails sent to:

```
jaradatm2@hotmail.com
```

For:

* ✅ Success
* ❌ Failure
* ⚠️ Unstable
* 🔁 State Change
* 🔧 Fixed
* 📦 Always (post actions)

---

## 🧩 Jenkinsfile Pipeline Breakdown

| Stage     | Description                                 |
| --------- | ------------------------------------------- |
| Checkout  | Clones the current repo                     |
| Pull Repo | Pulls latest code from GitHub               |
| Lint      | Lints `app.py` using `flake8`               |
| Build     | Sets up `venv`, installs deps, archives app |
| Test      | Runs `pytest`, saves coverage               |
| Deploy    | Executes `deploy.sh`, restarts service      |

---

## 📜 Deploy Script Summary (`deploy.sh`)

* Clones repo if missing
* Pulls latest from `main` branch
* Sets up virtual environment
* Installs dependencies
* Kills existing Streamlit process (if any)
* Restarts with:

```bash
sudo systemctl restart streamlit-app
```

---

## 🔒 Credentials & Permissions

* GitHub: SSH key-based access for Jenkins
* AWS: Access keys via Jenkins Credentials Binding plugin

---

## ✅ Final Notes

* Ensure **port 8501** is open in the EC2 security group
* Monitor Jenkins resource usage if the UI is slow or unresponsive
* Consider future enhancements like:

  * Docker-based deployment
  * Blue Ocean for visual pipelines
  * GitHub commit status checks

---
