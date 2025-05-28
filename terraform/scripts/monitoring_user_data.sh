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

# Set correct permissions
echo "Setting correct permissions..."
chown -R ec2-user:ec2-user /opt/prometheus
chown -R 472:472 /opt/grafana/data

# Create Prometheus config with Node Exporter target
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
      - targets: ['44.203.53.132:80']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Run Node Exporter container
echo "Starting Node Exporter container..."
docker run -d --name node-exporter \
  -p 9100:9100 \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter \
  --path.rootfs=/host || echo "Failed to start Node Exporter container"

# Run Prometheus container
echo "Starting Prometheus container..."
docker run -d --name prometheus \
  -p 9090:9090 \
  -v /opt/prometheus/config/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus || echo "Failed to start Prometheus container"

# Run Grafana container
echo "Starting Grafana container..."
docker run -d --name grafana \
  -p 3000:3000 \
  -v /opt/grafana/data:/var/lib/grafana \
  -e "GF_SECURITY_ADMIN_PASSWORD=admin" \
  -e "GF_USERS_ALLOW_SIGN_UP=false" \
  grafana/grafana || echo "Failed to start Grafana container"

echo "User data script completed at $(date)"
