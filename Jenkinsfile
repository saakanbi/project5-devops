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
        
        stage('Deploy with Ansible') {
            steps {
                sh '''
                    cd ansible
                    ansible-playbook -i inventory deploy.yml -e "app_version=${APP_VERSION} app_dir=/opt/flask_dashboard app_user=ec2-user app_port=8000"
                '''
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
// This Jenkinsfile defines a CI/CD pipeline for a Flask application with SonarQube analysis and Ansible deployment.