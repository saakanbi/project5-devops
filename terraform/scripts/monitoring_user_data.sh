#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Run Prometheus (9090) and Grafana (3000)
docker run -d --name prometheus -p 9090:9090 prom/prometheus
docker run -d --name grafana -p 3000:3000 grafana/grafana-oss
