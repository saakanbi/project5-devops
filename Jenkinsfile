pipeline {
    agent any
    environment {
        APP_NAME = 'flask-monitoring-dashboard'
        APP_VERSION = "${env.BUILD_NUMBER}"
        SONARQUBE_URL = "http://54.163.254.206:9000/"
        FLASK_SERVER = "3.222.89.93"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'SonarQube_token', variable: 'SONARQUBE_TOKEN')]) {
                    script {
                        def scannerHome = tool 'SonarQubeScanner'
                        withSonarQubeEnv('SonarQube') {
                            sh """${scannerHome}/bin/sonar-scanner \\
                                -Dsonar.projectKey=project_5 \\
                                -Dsonar.sources=. \\
                                -Dsonar.projectVersion=${APP_VERSION} \\
                                -Dsonar.host.url=${SONARQUBE_URL} \\
                                -Dsonar.login=${SONARQUBE_TOKEN}"""
                        }
                    }
                }
            }
        }
        
        stage('Package Application') {
            steps {
                sh '''
                    # Create deploy directory
                    mkdir -p "${WORKSPACE}/deploy"
                    
                    # Create a simplified prometheus_metrics.py
                    cat > "${WORKSPACE}/deploy/prometheus_metrics.py" << 'EOF'
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST
import time

# Application metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total app requests')
DASHBOARD_VIEWS = Counter('app_dashboard_views_total', 'Dashboard page views')

# Flask HTTP request metrics
HTTP_REQUEST_TOTAL = Counter('flask_http_request_total', 'Total HTTP requests', 
                            ['method', 'endpoint', 'status'])

def get_metrics():
    """Generate latest metrics"""
    return generate_latest()
EOF
                    
                    # Copy other application files
                    cp app/app.py app/Dockerfile app/requirements.txt "${WORKSPACE}/deploy/"
                    
                    # Create version file
                    echo "${APP_VERSION}" > "${WORKSPACE}/deploy/VERSION"
                    
                    # Verify files were copied
                    ls -la "${WORKSPACE}/deploy/"
                '''
            }
        }
        
        stage('Deploy Application') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Create remote directory
                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_SERVER} "mkdir -p /tmp/flask-app"
                        
                        # Copy files to Flask server
                        scp -o StrictHostKeyChecking=no -r "${WORKSPACE}/deploy/"* ec2-user@${FLASK_SERVER}:/tmp/flask-app/
                        
                        # SSH to server and deploy
                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_SERVER} "
                            sudo mkdir -p /opt/flask-app
                            sudo cp -r /tmp/flask-app/* /opt/flask-app/
                            cd /opt/flask-app
                            sudo pip3 install -r requirements.txt
                            
                            # Check the port in app.py
                            echo 'Checking Flask port:'
                            grep -r 'port=' /opt/flask-app/app.py
                            
                            # Create systemd service if it doesn't exist
                            sudo bash -c 'cat > /etc/systemd/system/flask-app.service << EOF
[Unit]
Description=Flask Application
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/opt/flask-app
ExecStart=/usr/bin/python3 -u app.py
Environment=PYTHONUNBUFFERED=1
Restart=always

[Install]
WantedBy=multi-user.target
EOF'
                            sudo systemctl daemon-reload
                            sudo systemctl enable flask-app
                            
                            # Start the service and check logs
                            sudo systemctl restart flask-app
                            sleep 5
                            echo 'Service status:'
                            sudo systemctl status flask-app
                            echo 'Service logs:'
                            sudo journalctl -u flask-app -n 20
                            
                            # Verify service is running
                            if sudo systemctl is-active --quiet flask-app; then
                                echo 'Flask application deployed successfully!'
                            else
                                echo 'Failed to start Flask application!'
                                exit 1
                            fi
                        "
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}
// This Jenkinsfile defines a CI/CD pipeline for a Flask application with SonarQube analysis, packaging, and deployment to an EC2 instance.
// It includes stages for checking out the code, running SonarQube analysis, packaging the application, and deploying it to a remote server.
// The pipeline uses environment variables for configuration and includes error handling to ensure the application is deployed correctly.
// The deployment stage uses SSH to copy files to the remote server, sets up a systemd service for the Flask application, and verifies that the service is running correctly.
// The pipeline also cleans up the workspace after completion.