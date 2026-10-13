#!/usr/bin/env bash
set -e

echo "=== Deploying Nord Rice Dotfiles ==="

# Copy config folders into ~/.config
mkdir -p ~/.config
cp -r polybar ~/.config/
cp -r rofi ~/.config/
cp -r picom ~/.config/ 2>/dev/null || true
cp -r kitty ~/.config/ 2>/dev/null || true

# Ensure all scripts are executable
chmod +x ~/.config/polybar/launch.sh
chmod +x ~/.config/polybar/scripts/*.sh

# Deploy autostart entries
mkdir -p ~/.config/autostart
cp autostart/*.desktop ~/.config/autostart/
chmod +x ~/.config/autostart/*.desktop

echo "Deployment complete! Run ~/.config/polybar/launch.sh to load."
