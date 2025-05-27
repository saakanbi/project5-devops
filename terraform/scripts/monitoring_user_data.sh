#!/bin/bash

# Setup logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting Monitoring user data script execution at $(date)"

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

# Create directories for Prometheus and Grafana
mkdir -p /opt/prometheus/config
mkdir -p /opt/grafana/data

# Create Prometheus config
cat > /opt/prometheus/config/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'flask_dashboard'
    metrics_path: /metrics
    static_configs:
      - targets: ['flask-app-alb-416560770.us-east-1.elb.amazonaws.com:80']
EOF

# Run Prometheus container
echo "Starting Prometheus container..."
docker run -d --name prometheus \
  -p 9090:9090 \
  -v /opt/prometheus/config:/etc/prometheus \
  prom/prometheus || echo "Failed to start Prometheus container"

# Run Grafana container
echo "Starting Grafana container..."
docker run -d --name grafana \
  -p 3000:3000 \
  -v /opt/grafana/data:/var/lib/grafana \
  grafana/grafana || echo "Failed to start Grafana container"

echo "User data script completed at $(date)"
