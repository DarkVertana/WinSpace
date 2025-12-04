#!/bin/bash
# Setup script for Linux development dependencies

echo "Installing Linux development dependencies for Flutter..."
echo "This requires sudo privileges."

sudo apt update
sudo apt install -y \
    ninja-build \
    clang \
    libgtk-3-dev \
    mesa-utils \
    build-essential \
    cmake \
    pkg-config

echo ""
echo "Dependencies installed! Verifying installation..."
flutter doctor -v

echo ""
echo "Setup complete! You can now run: flutter run -d linux"


