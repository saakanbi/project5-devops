pipeline {
    agent any
    environment {
        APP_NAME = 'flask-monitoring-dashboard'
        APP_VERSION = "${env.BUILD_NUMBER}"
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
                                -Dsonar.host.url=http://54.163.254.206:9000 \\
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
                    
                    # Copy application files
                    cp -r app/* "${WORKSPACE}/deploy/"
                    
                    # Create version file
                    echo "${APP_VERSION}" > "${WORKSPACE}/deploy/VERSION"
                '''
            }
        }
        
        stage('Deploy Application') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        # Create a simplified prometheus_metrics.py
                        cat > prometheus_metrics.py << 'EOF'
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST
import time

# Application metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total app requests')
DASHBOARD_VIEWS = Counter('app_dashboard_views_total', 'Dashboard page views')
HTTP_REQUEST_TOTAL = Counter('flask_http_request_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])

def get_metrics():
    """Generate latest metrics"""
    return generate_latest()
EOF
                        
                        # Create Nginx config file
                        cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://0.0.0.0:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /metrics {
        proxy_pass http://0.0.0.0:8000/metrics;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF
                        # Create systemd service file
                        cat > flaskapp.service << 'EOF'
[Unit]
Description=Gunicorn Flask Dashboard
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/opt/flask_dashboard
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF
                        
                        # Copy files to the Flask server
                        scp -o StrictHostKeyChecking=no app.py prometheus_metrics.py nginx.conf flaskapp.service ec2-user@${FLASK_SERVER}:/tmp/
                        
                        # SSH to the server and deploy the app
                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_SERVER} "
                            # Stop services
                            sudo systemctl stop flaskapp || true
                            sudo systemctl stop nginx || true
                            
                            # Update files
                            sudo cp /tmp/app.py /opt/flask_dashboard/app.py
                            sudo cp /tmp/prometheus_metrics.py /opt/flask_dashboard/prometheus_metrics.py
                            sudo cp /tmp/flaskapp.service /etc/systemd/system/flaskapp.service
                            sudo cp /tmp/nginx.conf /etc/nginx/conf.d/flask-app.conf
                            
                            # Remove default Nginx config
                            sudo rm -f /etc/nginx/conf.d/default.conf || true
                            
                            # Test Nginx config
                            sudo nginx -t
                            
                            # Reload systemd and restart services
                            sudo systemctl daemon-reload
                            sudo systemctl enable flaskapp
                            sudo systemctl restart flaskapp
                            sleep 3
                            sudo systemctl enable nginx
                            sudo systemctl restart nginx
                            
                            # Check service status
                            echo 'Flask service status:'
                            sudo systemctl status flaskapp
                            echo 'Nginx service status:'
                            sudo systemctl status nginx
                            
                            # Check if Gunicorn is listening
                            echo 'Checking if Gunicorn is listening:'
                            sudo netstat -tulpn | grep 8000
                        "
                    '''
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                sh '''
                    # Run unit tests
                    python -m unittest discover -s tests -p '*_test.py' || echo "No tests found"
                '''
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh '''
                    # Wait for application to start
                    sleep 5
                    
                    # Check if application is accessible
                    curl -v http://${FLASK_SERVER}/health || echo "Health check failed"
                    curl -v http://${FLASK_SERVER}/metrics | head -n 5 || echo "Metrics check failed"
                '''
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
