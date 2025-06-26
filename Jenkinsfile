pipeline {
    agent any
    environment {
        AUTHOR_NAME = 'Mohannad Jaradat'
        GIT_DIR = '/var/lib/jenkins/simple-jenkins-dockerized'
        APP_DIR = '/var/lib/jenkins/simple-jenkins-dockerized/streamlit_app'
        REPO_URL = 'git@github.com:MohannadmJaradat/simple-jenkins-dockerized.git'
        DEPLOY_BRANCH = "main"
    }
    stages {
        stage('Checkout to Custom Location') {
            steps {
                echo "📥 Checking out repository..."
                script {
                    // Clean the directory first
                    sh 'rm -rf /var/lib/jenkins/simple-jenkins-dockerized'
                    
                    // Clone to specific location
                    dir('/var/lib/jenkins/simple-jenkins-dockerized') {
                        git branch: 'main', 
                            url: 'https://github.com/MohannadmJaradat/simple-jenkins-dockerized.git'
                    }
                }
            }
        stage("Lint") {
            steps {
                echo "🧹 Linting app.py using flake8 in Docker..."
                sh '''
                cd "$APP_DIR"
                    docker run --rm -v $APP_DIR:/app python:3.11 \
                        bash -c "pip install flake8 && flake8 /app/app.py" > lint_report.txt || true
                '''
                archiveArtifacts artifacts: 'lint_report.txt'
            }
        }
        stage("Build") {
            steps {
                echo "🐳 Building Docker image..."
                sh '''
                    cd "$APP_DIR"
                    docker-compose build
                    tar --exclude=venv --exclude=app.tar.gz -czf app.tar.gz *
                '''
                archiveArtifacts 'app.tar.gz'
                echo "The author's name is: ${AUTHOR_NAME}"
            }
        }
        stage("Test") {
            steps {
                echo "🧪 Running tests inside container..."
                sh '''
                    cd "$APP_DIR"
                    docker run --rm -v $APP_DIR:/app python:3.11 \
                        bash -c "pip install pytest && pytest /app/test_app.py --maxfail=1 --disable-warnings" > coverage.txt || true
                '''
                archiveArtifacts artifacts: 'coverage.txt'
            }
        }
        stage("Deploy") {
            steps {
                echo "🚀 Running deploy script (Docker Compose)..."
                sh '''
                    chmod +x "$APP_DIR/deploy.sh"
                    bash "$APP_DIR/deploy.sh"
                '''
            }
        }
    }
    // post {
    //     always {
    //         echo "This will always run regardless of the completion status"
    //         mail to: 'jaradatm2@hotmail.com',
    //         subject: "📦 Pipeline Completed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
    //         body: "The pipeline has completed (success, failure, or otherwise).\n\nSee: ${env.BUILD_URL}"
    //     }
    //     success {
    //         echo "This will run if the build succeeded"
    //         mail to: 'jaradatm2@hotmail.com',
    //         subject: "✅ Build Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
    //         body: "The build was successful.\n\nSee: ${env.BUILD_URL}"
    //     }
    //     failure {
    //         echo "This will run if the job failed"
    //         mail to: 'jaradatm2@hotmail.com',
    //         subject: "❌ Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
    //         body: "The build has failed.\n\nCheck the console: ${env.BUILD_URL}"
    //     }
    //     unstable {
    //         echo "This will run if the completion status was 'unstable', usually by test failures"
    //         mail to: 'jaradatm2@hotmail.com',
    //         subject: "⚠️ Build Unstable: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
    //         body: "The build is unstable, usually due to test failures.\n\nSee: ${env.BUILD_URL}"
    //     }
    //     changed {
    //         echo "This will run if the state of the pipeline has changed"
    //         echo "For example, if the previous run failed but is now successful"
    //         mail to: 'jaradatm2@hotmail.com',
    //         subject: "🔁 Pipeline State Changed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
    //         body: "The build status has changed from the last run (e.g., failed to passed).\n\nSee: ${env.BUILD_URL}"
    //     }
    //     fixed {
    //         echo "This will run if the previous run failed or unstable and now is successful"
    //         mail to: 'jaradatm2@hotmail.com',
    //         subject: "🔧 Build Fixed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
    //         body: "The build is now successful after previously failing or being unstable.\n\nSee: ${env.BUILD_URL}"
    //     }
    //     // cleanup {
    //     //     echo "🧹 Cleaning the workspace...."
    //     //     cleanWs()
    //     // }
    // }

}
