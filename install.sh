#!/bin/bash

set -e

# Update package list
apt-get update -y

# Install required packages
apt-get install -y curl unzip

# Create temporary directory
TMP_DIR=$(mktemp -d)
ZIP_FILE="$TMP_DIR/setup.zip"
APP_DIR="$TMP_DIR/app"

# Download setup.zip from GitHub Release
curl -fL "https://github.com/Degeris/Degeris/releases/download/1.52/setup.zip" -o "$ZIP_FILE"

# Extract setup.zip
mkdir -p "$APP_DIR"
unzip -q "$ZIP_FILE" -d "$APP_DIR"

# Go to extracted application directory
cd "$APP_DIR"

# Run the original installer
bash ./install.sh

# Clean up temporary files
rm -rf "$TMP_DIR"
