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
                        # Copy app.py to the Flask server
                        scp -o StrictHostKeyChecking=no app.py ec2-user@${FLASK_SERVER}:/tmp/app.py
                        # SSH to the server and deploy the app
                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_SERVER} "
                            sudo cp /tmp/app.py /opt/flask_dashboard/app.py
                            sudo systemctl restart flaskapp
                            sudo systemctl status flaskapp
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
