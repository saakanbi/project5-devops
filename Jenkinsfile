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
                    
                    # Copy application files
                    cp -r app/* "${WORKSPACE}/deploy/"
                    
                    # Create version file
                    echo "${APP_VERSION}" > "${WORKSPACE}/deploy/VERSION"
                    
                    # Verify files were copied
                    ls -la "${WORKSPACE}/deploy/"
                '''
            }
        }
        
        stage('Deploy Application') {
            steps {
                sshagent(['ansible-key']) {
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
                            
                            # Create systemd service if it doesn't exist
                            if [ ! -f /etc/systemd/system/flask-app.service ]; then
                                sudo bash -c 'cat > /etc/systemd/system/flask-app.service << EOF
[Unit]
Description=Flask Application
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/opt/flask-app
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF'
                                sudo systemctl daemon-reload
                                sudo systemctl enable flask-app
                            fi
                            
                            sudo systemctl restart flask-app
                            
                            # Verify service is running
                            sleep 5
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
        
        stage('Setup Monitoring') {
            steps {
                sshagent(['ansible-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_SERVER} "
                            # Install Prometheus if not installed
                            if ! command -v prometheus &> /dev/null; then
                                sudo yum install -y wget
                                wget https://github.com/prometheus/prometheus/releases/download/v2.37.0/prometheus-2.37.0.linux-amd64.tar.gz
                                tar xvfz prometheus-*.tar.gz
                                sudo cp prometheus-*/prometheus /usr/local/bin/
                                sudo mkdir -p /etc/prometheus
                            fi
                            
                            # Create Prometheus config
                            sudo bash -c 'cat > /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "flask-app"
    static_configs:
      - targets: ["localhost:5000"]
    metrics_path: "/metrics"
EOF'
                            
                            # Create Prometheus service if it doesn't exist
                            if [ ! -f /etc/systemd/system/prometheus.service ]; then
                                sudo bash -c 'cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF'
                                sudo systemctl daemon-reload
                                sudo systemctl enable prometheus
                            fi
                            
                            sudo systemctl restart prometheus
                            
                            # Verify Prometheus is running
                            sleep 5
                            if sudo systemctl is-active --quiet prometheus; then
                                echo 'Prometheus started successfully!'
                            else
                                echo 'Failed to start Prometheus!'
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
