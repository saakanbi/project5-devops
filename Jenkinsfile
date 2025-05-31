pipeline {
    agent any
    
    environment {
        IMAGE_NAME = "flask-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        FLASK_HOST = "3.222.89.93" // Your Flask app Elastic IP
        NEXUS_URL = "http://44.218.100.248:8081" // Your Nexus Elastic IP
        NEXUS_REPOSITORY = "flask-app" // Repository name in Nexus
        PROMETHEUS_PORT = "9090" // Prometheus port
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
                    sh 'cd app && pip install -r requirements.txt'
                    sh 'cd app && pip install pytest pytest-cov'
                    sh 'cd app && pytest --cov=. --cov-report=xml:../coverage.xml'
                    sh 'sonar-scanner'
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
        
        stage('Publish to Nexus') {
            steps {
                dir('app') {
                    sh "zip -r flask-app-${IMAGE_TAG}.zip ."
                    withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                            curl -v -u ${NEXUS_USER}:${NEXUS_PASS} --upload-file flask-app-${IMAGE_TAG}.zip ${NEXUS_URL}/repository/${NEXUS_REPOSITORY}/flask-app/flask-app-${IMAGE_TAG}.zip
                        """
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                dir('app') {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }
        
        stage('Deploy') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_HOST} '
                            docker stop flask-app || true
                            docker rm flask-app || true
                            docker run -d --name flask-app -p 80:5000 -p 9090:9090 --restart=always ${IMAGE_NAME}:${IMAGE_TAG}
                        '
                    """
                }
            }
        }
        
        stage('Setup Monitoring') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                        scp -o StrictHostKeyChecking=no ${WORKSPACE}/grafana-dashboard.json ec2-user@${FLASK_HOST}:~/dashboard.json
                        ssh -o StrictHostKeyChecking=no ec2-user@${FLASK_HOST} '
                            # Create prometheus config
                            cat > prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "flask-app"
    static_configs:
      - targets: ["localhost:5000"]
    metrics_path: "/metrics"
EOF
                            
                            # Run Prometheus container if not already running
                            docker ps | grep prometheus || docker run -d \\
                              --name prometheus \\
                              -p 9090:9090 \\
                              -v \$(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \\
                              prom/prometheus
                              
                            # Setup Grafana if not already running
                            docker ps | grep grafana || docker run -d \\
                              --name grafana \\
                              -p 3000:3000 \\
                              --link prometheus:prometheus \\
                              grafana/grafana
                              
                            # Wait for Grafana to start
                            sleep 10
                              
                            # Create Grafana datasource
                            curl -s -X POST -H "Content-Type: application/json" \\
                              -d '\''{"name":"Prometheus","type":"prometheus","url":"http://prometheus:9090","access":"proxy","isDefault":true}'\'' \\
                              http://admin:admin@localhost:3000/api/datasources || true
                              
                            # Import dashboard
                            curl -s -X POST -H "Content-Type: application/json" \\
                              -d '\''{"dashboard": '\''$(cat dashboard.json | tr -d "\\n")'\'',"overwrite": true}'\'' \\
                              http://admin:admin@localhost:3000/api/dashboards/db || true
                        '
                    """
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
