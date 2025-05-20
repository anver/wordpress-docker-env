#!/bin/bash

# Install composer inside alpine container

# Check if composer is already installed
if command -v composer &>/dev/null; then
  echo "Composer is already installed"
  exit 0
fi

# Install using apk package manager
apk add --no-cache composer
# Check if installation was successful
if command -v composer &>/dev/null; then
  echo "Composer installed successfully"
else
  echo "Composer installation failed"
  exit 1
fi
