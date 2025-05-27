#!/bin/bash

# Setup logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user data script execution at $(date)"

# Basic system setup
echo "Updating system packages..."
yum update -y || echo "Yum update failed but continuing"

# Ensure SSH is properly configured and running
echo "Ensuring SSH is properly configured..."
systemctl restart sshd
systemctl status sshd

echo "User data script completed at $(date)"
