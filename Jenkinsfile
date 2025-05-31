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
                    
                    # Create wsgi.py file for Gunicorn
                    cat > "${WORKSPACE}/deploy/wsgi.py" << 'EOF'
from app import app

if __name__ == "__main__":
    app.run()
EOF
                    
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
                            # Clean up existing processes
                            sudo systemctl stop flask-app || true
                            sudo systemctl stop nginx || true
                            sudo pkill -f gunicorn || true
                            sudo pkill -f flask || true
                            sudo fuser -k 80/tcp || true
                            sudo fuser -k 8000/tcp || true
                            
                            # Install Nginx if not already installed
                            if ! command -v nginx &> /dev/null; then
                                sudo amazon-linux-extras install nginx1 -y || sudo yum install -y nginx
                            fi
                            
                            sudo mkdir -p /opt/flask-app
                            sudo cp -r /tmp/flask-app/* /opt/flask-app/
                            cd /opt/flask-app
                            sudo pip3 install -r requirements.txt
                            
                            # Create Gunicorn systemd service
                            sudo bash -c 'cat > /etc/systemd/system/flask-app.service << EOF
[Unit]
Description=Gunicorn instance to serve Flask application
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/flask-app
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 wsgi:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

                            # Configure Nginx
                            sudo bash -c 'cat > /etc/nginx/conf.d/flask-app.conf << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
    }
    
    location /metrics {
        proxy_pass http://127.0.0.1:8000/metrics;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
    }
}
EOF'
                            
                            # Remove default nginx config if it exists
                            sudo rm -f /etc/nginx/conf.d/default.conf
                            
                            # Test Nginx config
                            sudo nginx -t
                            
                            # Reload systemd, restart services
                            sudo systemctl daemon-reload
                            sudo systemctl enable flask-app
                            sudo systemctl restart flask-app
                            sleep 5
                            sudo systemctl enable nginx
                            sudo systemctl restart nginx
                            sleep 5
                            
                            # Check if services are running
                            echo 'Gunicorn service status:'
                            sudo systemctl status flask-app
                            
                            echo 'Nginx service status:'
                            sudo systemctl status nginx
                            
                            # Check listening ports
                            echo 'Listening ports:'
                            sudo netstat -tulpn | grep -E ':(80|8000)' || echo 'No processes listening on required ports'
                            
                            # Verify app is accessible
                            echo 'Testing application:'
                            curl -v http://localhost/health || echo 'Health check failed'
                            
                            # Verify services are running
                            if sudo systemctl is-active --quiet flask-app && sudo systemctl is-active --quiet nginx; then
                                echo 'Flask application deployed successfully!'
                            else
                                echo 'Failed to start services!'
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
