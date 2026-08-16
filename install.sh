#!/bin/bash

set -e

TMP_DIR=$(mktemp -d)
ZIP_FILE="$TMP_DIR/setup.zip"
APP_DIR="$TMP_DIR/app"

curl -fL "https://github.com/Degeris/Degeris/releases/download/1.0.0/setup.zip" -o "$ZIP_FILE"

mkdir -p "$APP_DIR"
unzip -q "$ZIP_FILE" -d "$APP_DIR"

cd "$APP_DIR"

bash ./install.sh

rm -rf "$TMP_DIR"
