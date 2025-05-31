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
                        # Download and install SonarScanner if not available
                        if ! command -v sonar-scanner &> /dev/null; then
                            echo "Installing SonarScanner..."
                            wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.7.0.2747-linux.zip
                            unzip sonar-scanner-cli-4.7.0.2747-linux.zip
                            export PATH=$PATH:$PWD/sonar-scanner-4.7.0.2747-linux/bin
                        fi
                        
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
                sshagent(['ansible_key']) {
                    sh "ansible-playbook -i ${ANSIBLE_INVENTORY} ${WORKSPACE}/ansible/deploy_flask.yml -e app_version=${APP_VERSION}"
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
