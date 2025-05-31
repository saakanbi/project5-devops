#!/bin/bash

# Script to create Nexus repositories via REST API
# Usage: ./nexus-setup.sh <nexus_url> <admin_user> <admin_password>

NEXUS_URL=$1
NEXUS_USER=$2
NEXUS_PASS=$3

# Create raw repository for application artifacts
curl -u $NEXUS_USER:$NEXUS_PASS -X POST "$NEXUS_URL/service/rest/v1/repositories/raw/hosted" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "flask-app",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": false,
      "writePolicy": "ALLOW"
    }
  }'

# Create docker hosted repository
curl -u $NEXUS_USER:$NEXUS_PASS -X POST "$NEXUS_URL/service/rest/v1/repositories/docker/hosted" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "docker-hosted",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true,
      "writePolicy": "ALLOW"
    },
    "docker": {
      "v1Enabled": false,
      "forceBasicAuth": true,
      "httpPort": 8082
    }
  }'

echo "Nexus repositories created successfully"