#!/bin/bash
set -e

echo "=== Installing Dependencies ==="
# Check for unzip, install if missing
if ! command -v unzip &> /dev/null; then
    echo "'unzip' not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y unzip
else
    echo "'unzip' is already installed."
fi

# Check for curl (should be there)
if ! command -v curl &> /dev/null; then
    echo "'curl' not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y curl
fi

echo -e "\n=== Installing AWS CLI v2 ==="
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update

# Cleanup
rm -rf aws awscliv2.zip

echo -e "\n=== Verification ==="
aws --version
echo "AWS CLI installed successfully!"
