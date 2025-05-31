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
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF'
                            
                            # Reload systemd and start flaskapp
                            sudo systemctl daemon-reload
                            sudo systemctl enable flaskapp
                            sudo systemctl restart flaskapp
                            
                            # Ensure Nginx is configured and running
                            sudo systemctl restart nginx
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
                    curl -s http://${FLASK_SERVER}/health || echo "Health check failed"
                    curl -s http://${FLASK_SERVER}/metrics | head -n 5 || echo "Metrics check failed"
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
// This Jenkinsfile defines a CI/CD pipeline for deploying a Flask application with SonarQube analysis, packaging, and deployment to an EC2 instance.