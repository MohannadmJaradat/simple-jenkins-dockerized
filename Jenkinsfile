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
        // always {
        //     echo "This will always run regardless of the completion status"
        //     mail to: 'jaradatm2@hotmail.com',
        //     subject: "📦 Pipeline Completed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
        //     body: "The pipeline has completed (success, failure, or otherwise).\n\nSee: ${env.BUILD_URL}"
        // }
        // success {
        //     echo "This will run if the build succeeded"
        //     mail to: 'jaradatm2@hotmail.com',
        //     subject: "✅ Build Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
        //     body: "The build was successful.\n\nSee: ${env.BUILD_URL}"
        // }
        // failure {
        //     echo "This will run if the job failed"
        //     mail to: 'jaradatm2@hotmail.com',
        //     subject: "❌ Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
        //     body: "The build has failed.\n\nCheck the console: ${env.BUILD_URL}"
        // }
        // unstable {
        //     echo "This will run if the completion status was 'unstable', usually by test failures"
        //     mail to: 'jaradatm2@hotmail.com',
        //     subject: "⚠️ Build Unstable: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
        //     body: "The build is unstable, usually due to test failures.\n\nSee: ${env.BUILD_URL}"
        // }
        // changed {
        //     echo "This will run if the state of the pipeline has changed"
        //     echo "For example, if the previous run failed but is now successful"
        //     mail to: 'jaradatm2@hotmail.com',
        //     subject: "🔁 Pipeline State Changed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
        //     body: "The build status has changed from the last run (e.g., failed to passed).\n\nSee: ${env.BUILD_URL}"
        // }
        // fixed {
        //     echo "This will run if the previous run failed or unstable and now is successful"
        //     mail to: 'jaradatm2@hotmail.com',
        //     subject: "🔧 Build Fixed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
        //     body: "The build is now successful after previously failing or being unstable.\n\nSee: ${env.BUILD_URL}"
        // }
        cleanup {
            echo "🧹 Cleaning the workspace...."
            cleanWs()
        }
    }
}