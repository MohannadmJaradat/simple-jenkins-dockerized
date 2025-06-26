pipeline {
    agent any
    
    environment {
        AUTHOR_NAME = 'Mohannad Jaradat'
        WORKSPACE_DIR = '/var/lib/jenkins/simple-jenkins-dockerized'  // Renamed from GIT_DIR
        APP_DIR = '/var/lib/jenkins/simple-jenkins-dockerized/streamlit_app'
        REPO_URL = 'https://github.com/MohannadmJaradat/simple-jenkins-dockerized.git'
        DEPLOY_BRANCH = "main"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "📥 Checking out repository..."
                script {
                    // Clean the directory first
                    sh 'sudo rm -rf /var/lib/jenkins/simple-jenkins-dockerized || true'
                    
                    // Clone to specific location
                    dir('/var/lib/jenkins/simple-jenkins-dockerized') {
                        git branch: 'main', 
                            url: 'https://github.com/MohannadmJaradat/simple-jenkins-dockerized.git'
                    }
                }
            }
        }
        
        stage("Lint") {
            steps {
                echo "🧹 Linting app.py using flake8..."
                dir("${APP_DIR}") {
                    sh '''
                        docker run --rm -v $(pwd):/app python:3.11 \
                            bash -c "pip install flake8 && flake8 /app/app.py" \
                            | tee lint_report.txt || true
                    '''
                    archiveArtifacts artifacts: 'lint_report.txt', allowEmptyArchive: true
                }
            }
        }
        
        stage("Test") {
            steps {
                echo "🧪 Running tests..."
                dir("${APP_DIR}") {
                    sh '''
                        docker run --rm -v $(pwd):/app python:3.11 \
                            bash -c "pip install pytest && pytest /app/test_app.py --maxfail=1 --disable-warnings" \
                            | tee coverage.txt || true
                    '''
                    archiveArtifacts artifacts: 'coverage.txt', allowEmptyArchive: true
                }
            }
        }
        
        stage("Build & Deploy") {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    echo "🐳 Building and deploying application..."
                    dir("${APP_DIR}") {
                        script {
                            sh '''
                                echo "🛑 Stopping existing containers..."
                                sudo docker-compose down --remove-orphans || true
                                
                                echo "🧹 Cleaning Docker cache..."
                                sudo docker system prune -f || true
                                
                                echo "🐳 Building fresh containers..."
                                sudo docker-compose build --no-cache --pull
                                
                                echo "🚀 Starting containers..."
                                sudo docker-compose up -d
                                
                                echo "⏳ Waiting for container to be ready..."
                                sleep 5
                                
                                echo "🔍 Checking container status..."
                                sudo docker-compose ps
                                
                                # Verify the container is running
                                if sudo docker-compose ps | grep -q "Up"; then
                                    echo "✅ Deployment successful!"
                                    echo "🌐 App should be available at: http://localhost:8501"
                                else
                                    echo "❌ Container failed to start"
                                    echo "📋 Container logs:"
                                    sudo docker-compose logs --tail=20
                                    exit 1
                                fi
                            '''
                        }
                    }
                }
            }
        }
        
        stage("Archive") {
            steps {
                echo "📦 Creating deployment archive..."
                dir("${APP_DIR}") {
                    sh '''
                        tar --exclude=venv --exclude=__pycache__ --exclude=.pytest_cache \
                            --exclude=*.tar.gz -czf app.tar.gz *
                    '''
                    archiveArtifacts artifacts: 'app.tar.gz'
                }
                echo "👤 Build completed by: ${AUTHOR_NAME}"
            }
        }
    }
    
    post {
        always {
            echo "🧹 Pipeline completed"
        }
        success {
            echo "✅ Pipeline succeeded"
        }
        failure {
            echo "❌ Pipeline failed"
            // Show recent logs for debugging
            script {
                sh 'sudo docker-compose -f ${APP_DIR}/docker-compose.yml logs --tail=30 || true'
            }
        }
    }
}