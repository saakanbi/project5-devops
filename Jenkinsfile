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
                dir('app') {
                    sh "find . -name '*.pyc' -delete || true"
                    sh "tar --exclude='*.git*' --exclude='*.pyc' -czf flask-app-${APP_VERSION}.tar.gz ."
                    sh "mkdir -p ${WORKSPACE}/ansible/files"
                    sh "cp flask-app-${APP_VERSION}.tar.gz ${WORKSPACE}/ansible/files/"
                }
            }
        }
        
        stage('Deploy with Ansible') {
            steps {
                sshagent(['ansible-key']) {
                    sh "ansible-playbook -i ${ANSIBLE_INVENTORY} ${WORKSPACE}/ansible/deploy_flask.yml -e app_version=${APP_VERSION} -e archive_ext=tar.gz"
                }
            }
        }
        
        stage('Setup Monitoring') {
            steps {
                sshagent(['ansible-key']) {
                    sh "ansible-playbook -i ${ANSIBLE_INVENTORY} ${WORKSPACE}/ansible/site.yml --tags monitoring"
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
