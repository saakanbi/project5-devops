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
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        # Install required packages
                        apt-get update && apt-get install -y wget unzip || yum install -y wget unzip
                        
                        # Download and install SonarScanner
                        wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.7.0.2747-linux.zip
                        unzip -o sonar-scanner-cli-4.7.0.2747-linux.zip
                        
                        # Run SonarScanner
                        ./sonar-scanner-4.7.0.2747-linux/bin/sonar-scanner \
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
