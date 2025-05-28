# DevOps CI/CD Pipeline Project

A comprehensive DevOps pipeline for a Flask application with infrastructure as code, continuous integration, continuous deployment, and monitoring.

## Architecture Overview

![Architecture Diagram](https://via.placeholder.com/800x400?text=Architecture+Diagram)

This project implements a complete DevOps pipeline with the following components:

- **Infrastructure**: AWS resources provisioned with Terraform
- **Configuration Management**: Ansible for server configuration
- **CI/CD**: Jenkins pipeline for build, test, and deployment
- **Code Quality**: SonarQube for code analysis
- **Artifact Repository**: Nexus for storing Docker images
- **Monitoring**: Prometheus and Grafana for metrics collection and visualization

## Infrastructure Components

| Service | Public IP | Purpose |
|---------|-----------|---------|
| Flask App | 44.203.53.132 | Application server with load balancer |
| Jenkins | 18.212.250.55 | CI/CD server |
| Monitoring Stack | 54.159.146.237 | Prometheus and Grafana |
| Nexus | 54.91.22.91 | Artifact repository |
| SonarQube | 54.91.58.139 | Code quality analysis |

## Getting Started

### Prerequisites

- AWS account with appropriate permissions
- Terraform installed locally
- Ansible installed locally
- Git

### Deployment Steps

1. **Provision Infrastructure**:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

2. **Configure Servers**:
   ```bash
   cd ansible
   ansible-playbook -i inventory site.yml
   ```

3. **Set Up Jenkins Pipeline**:
   - Navigate to Jenkins at http://18.212.250.55:8080
   - Create a new pipeline job
   - Configure it to use the Jenkinsfile from this repository

## CI/CD Pipeline

The Jenkins pipeline includes the following stages:

1. **Checkout**: Retrieves code from the repository
2. **Build Application**: Installs dependencies and runs tests
3. **SonarQube Analysis**: Analyzes code quality
4. **Quality Gate**: Ensures code meets quality standards
5. **Build Docker Image**: Creates a Docker image of the application
6. **Push to Nexus**: Stores the Docker image in Nexus
7. **Deploy**: Deploys the application to the Flask server
8. **Update Prometheus Config**: Updates monitoring configuration
9. **Update Grafana Dashboard**: Updates visualization dashboards

## Monitoring

- **Prometheus**: http://54.159.146.237:9090
- **Grafana**: http://54.159.146.237:3000

## Code Quality

- **SonarQube**: http://54.91.58.139:9000

## Artifact Repository

- **Nexus**: http://54.91.22.91:8081

## Application

- **Flask App**: http://flask-app-alb-416560770.us-east-1.elb.amazonaws.com

## Project Structure

- `/ansible`: Ansible playbooks and roles
- `/app`: Flask application code
- `/grafana`: Grafana dashboard configurations
- `/jenkins`: Jenkins pipeline configuration
- `/prometheus`: Prometheus configuration
- `/terraform`: Infrastructure as code

## Demo Instructions

1. **Infrastructure Demo**:
   - Show the AWS resources created by Terraform
   - Explain the network architecture and security groups

2. **CI/CD Pipeline Demo**:
   - Make a code change to the Flask application
   - Push the change to trigger the Jenkins pipeline
   - Walk through each stage of the pipeline execution

3. **Monitoring Demo**:
   - Show the Prometheus targets and metrics
   - Display the Grafana dashboards for the Flask application
   - Demonstrate how metrics change when the application is under load

4. **Code Quality Demo**:
   - Show the SonarQube dashboard
   - Explain the quality gates and code coverage

## Future Enhancements

- Implement Infrastructure as Code for Jenkins configuration
- Add automated security scanning with OWASP ZAP
- Implement blue/green deployment strategy
- Add automated performance testing