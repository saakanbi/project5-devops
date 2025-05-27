#!/bin/bash
yum update -y
yum install -y python3 python3-pip nginx
pip3 install flask gunicorn prometheus_client

mkdir -p /opt/flask_dashboard
echo "<h1>Flask App Ready</h1>" > /opt/flask_dashboard/index.html

systemctl enable nginx
systemctl start nginx
