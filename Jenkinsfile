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
                    mkdir -p "$WORKSPACE/deploy"

                    cat > "$WORKSPACE/deploy/prometheus_metrics.py" << 'EOF'
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST
import time

REQUEST_COUNT = Counter('app_requests_total', 'Total app requests')
DASHBOARD_VIEWS = Counter('app_dashboard_views_total', 'Dashboard page views')
HTTP_REQUEST_TOTAL = Counter('flask_http_request_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])

def get_metrics():
    return generate_latest()
EOF

                    cp app/app.py app/Dockerfile app/requirements.txt "$WORKSPACE/deploy/"
                    echo "${APP_VERSION}" > "$WORKSPACE/deploy/VERSION"

                    cat > "$WORKSPACE/deploy/wsgi.py" << 'EOF'
from app import app

if __name__ == "__main__":
    app.run()
EOF

                    ls -la "$WORKSPACE/deploy/"
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_SERVER} "mkdir -p /tmp/flask-app"

                        scp -o StrictHostKeyChecking=no -r $WORKSPACE/deploy/* ec2-user@${FLASK_SERVER}:/tmp/flask-app/

                        cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /metrics {
        proxy_pass http://127.0.0.1:8000/metrics;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

                        scp -o StrictHostKeyChecking=no nginx.conf ec2-user@${FLASK_SERVER}:/tmp/nginx.conf

                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_SERVER} << 'EOF'
set -e

sudo systemctl stop flask-app || true
sudo systemctl stop nginx || true
sudo pkill -f gunicorn || true
sudo pkill -f flask || true
sudo fuser -k 80/tcp || true
sudo fuser -k 8000/tcp || true

if ! command -v nginx &> /dev/null; then
    sudo amazon-linux-extras install nginx1 -y || sudo yum install -y nginx
fi

sudo mkdir -p /opt/flask-app
sudo cp -r /tmp/flask-app/* /opt/flask-app/
cd /opt/flask-app
sudo pip3 install -r requirements.txt

sudo bash -c 'cat > /etc/systemd/system/flask-app.service << FLASKSERVICE
[Unit]
Description=Gunicorn instance to serve Flask application
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/flask-app
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 wsgi:app
Restart=always

[Install]
WantedBy=multi-user.target
FLASKSERVICE'

sudo cp /tmp/nginx.conf /etc/nginx/conf.d/flask-app.conf
sudo rm -f /etc/nginx/conf.d/default.conf

sudo nginx -t
sudo systemctl daemon-reload
sudo systemctl enable flask-app
sudo systemctl restart flask-app
sleep 5
sudo systemctl enable nginx
sudo systemctl restart nginx
sleep 5

echo 'Gunicorn service status:'
sudo systemctl status flask-app

echo 'Nginx service status:'
sudo systemctl status nginx

echo 'Testing application:'
curl -v http://localhost/health || echo 'Health check failed'
EOF
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}
