#!/bin/bash

# Install composer inside alpine container

# Check if composer is already installed
if command -v composer &>/dev/null; then
  echo "Composer is already installed"
  exit 0
fi

# Install composer using curl
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Check if installation was successful
if command -v composer &>/dev/null; then
  echo "Composer installed successfully"
else
  echo "Composer installation failed"
  exit 1
fi
