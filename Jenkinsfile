pipeline {
    agent any
    
    environment {
        APP_VERSION = "${env.BUILD_NUMBER}"
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
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                        -Dsonar.projectKey=project_5 \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=http://54.163.254.206:9000
                    '''
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        

        
        stage('Package Application') {
            steps {
                dir('app') {
                    sh "zip -r flask-app-${APP_VERSION}.zip ."
                    sh "mkdir -p ${WORKSPACE}/ansible/files"
                    sh "cp flask-app-${APP_VERSION}.zip ${WORKSPACE}/ansible/files/"
                }
            }
        }
        
        stage('Deploy with Ansible') {
            steps {
                ansiblePlaybook(
                    playbook: "${WORKSPACE}/ansible/deploy_flask.yml",
                    inventory: "${WORKSPACE}/ansible/inventory",
                    extras: "-e app_version=${APP_VERSION}"
                )
            }
        }
        
        stage('Setup Monitoring') {
            steps {
                ansiblePlaybook(
                    playbook: "${WORKSPACE}/ansible/site.yml",
                    inventory: "${WORKSPACE}/ansible/inventory",
                    tags: "monitoring"
                )
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
