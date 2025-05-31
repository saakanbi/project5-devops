pipeline {
    agent any
    environment {
        APP_NAME = 'flask-monitoring-dashboard'
        APP_VERSION = "${env.BUILD_NUMBER}"
        SONARQUBE_URL = "http://54.163.254.206:9000/"
        ANSIBLE_INVENTORY = "${WORKSPACE}/ansible/inventory"
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
                    # Create ansible files directory
                    mkdir -p "${WORKSPACE}/ansible/files"
                    
                    # Copy application files directly
                    cp -r app/* "${WORKSPACE}/ansible/files/"
                    
                    # Create a version file
                    echo "${APP_VERSION}" > "${WORKSPACE}/ansible/files/VERSION"
                '''
            }
        }
        
        stage('Deploy Application') {
            steps {
                sshagent(['ansible-key']) {
                    sh '''
                        # Copy files to Flask server
                        scp -r "${WORKSPACE}/ansible/files/"* ec2-user@3.222.89.93:/tmp/flask-app/
                        
                        # SSH to server and deploy
                        ssh ec2-user@3.222.89.93 "
                            sudo mkdir -p /opt/flask-app
                            sudo cp -r /tmp/flask-app/* /opt/flask-app/
                            cd /opt/flask-app
                            sudo pip3 install -r requirements.txt
                            sudo systemctl restart flask-app || sudo systemctl start flask-app
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
