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
                        # Create remote directory
                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_SERVER} "mkdir -p /tmp/flask-app"
                        
                        # Copy files to Flask server
                        scp -o StrictHostKeyChecking=no -r "${WORKSPACE}/deploy/"* ec2-user@${FLASK_SERVER}:/tmp/flask-app/
                        
                        # SSH to server and deploy
                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_SERVER} "
                            # Stop existing services
                            sudo systemctl stop flaskapp || true
                            sudo systemctl stop nginx || true
                            
                            # Copy application files
                            sudo mkdir -p /opt/flask_dashboard
                            sudo cp -r /tmp/flask-app/* /opt/flask_dashboard/
                            cd /opt/flask_dashboard
                            sudo pip3 install -r requirements.txt
                            
                            # Create systemd service for Gunicorn
                            sudo bash -c 'cat > /etc/systemd/system/flaskapp.service << EOF
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
EOF'
                            
                            # Create Nginx server block
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
                            
                            # Remove default Nginx config
                            sudo rm -f /etc/nginx/conf.d/default.conf || true
                            
                            # Test Nginx configuration
                            sudo nginx -t
                            
                            # Reload systemd and start services
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
                            
                            # Check Nginx error log
                            echo 'Nginx error log:'
                            sudo tail -n 20 /var/log/nginx/error.log
                        "
                    '''
                }
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
