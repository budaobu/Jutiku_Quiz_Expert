#!/bin/bash
# Basic installation for Debian/Ubuntu
if [ -f /etc/debian_version ]; then
    echo "Detected Debian/Ubuntu system."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
elif [ -f /etc/redhat-release ]; then
    echo "Detected RedHat/CentOS/Fedora system."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y nodejs
    else
        sudo yum install -y nodejs
    fi
else
    echo "Unsupported Linux distribution. Please install Node.js manually."
fi
