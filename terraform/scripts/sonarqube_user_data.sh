#!/bin/bash

# Setup logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting SonarQube user data script execution at $(date)"

# Basic system setup
echo "Updating system packages..."
yum update -y || echo "Yum update failed but continuing"
echo "Installing docker..."
amazon-linux-extras install -y docker || echo "Failed to install docker from amazon-linux-extras"

# Enable and start Docker
echo "Enabling and starting Docker..."
systemctl enable docker
systemctl start docker || echo "Failed to start Docker"

# Add ec2-user to docker group
echo "Adding ec2-user to docker group..."
usermod -aG docker ec2-user

# Run SonarQube container
echo "Starting SonarQube container..."
docker run -d --name sonarqube -p 9000:9000 sonarqube || echo "Failed to start SonarQube container"

echo "User data script completed at $(date)"
