pipeline {
    agent any
    
    environment {
        APP_VERSION = "${env.BUILD_NUMBER}"
        ANSIBLE_INVENTORY = "${WORKSPACE}/ansible/inventory"
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Package Application') {
            steps {
                dir('app') {
                    sh "tar -czf flask-app-${APP_VERSION}.tar.gz ."
                    sh "mkdir -p ${WORKSPACE}/ansible/files"
                    sh "cp flask-app-${APP_VERSION}.tar.gz ${WORKSPACE}/ansible/files/"
                }
            }
        }
        
        stage('Deploy with Ansible') {
            steps {
                sshagent(['ansible_key']) {
                    sh "ansible-playbook -i ${ANSIBLE_INVENTORY} ${WORKSPACE}/ansible/deploy_flask.yml -e app_version=${APP_VERSION} -e archive_ext=tar.gz"
                }
            }
        }
        
        stage('Setup Monitoring') {
            steps {
                sshagent(['ansible_key']) {
                    sh "ansible-playbook -i ${ANSIBLE_INVENTORY} ${WORKSPACE}/ansible/site.yml --tags monitoring"
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
