#!/usr/bin/env bash
# ==============================================================================
# KinStock - Cloudflare Quick Tunnel (Free, No Sign-up Required HTTPS Public URL)
# Exposes the Flutter Web App (Port 3000) & Backend API (Port 8000)
# ==============================================================================

set -e

PORT=${1:-3000}
echo "🚀 Starting KinStock Public Tunnel for Port $PORT..."

# 1. Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "⚠️  'cloudflared' is not installed."
    echo "📦 Attempting to install via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install cloudflared
    else
        echo "❌ Homebrew not found. Please install cloudflared manually: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
        exit 1
    fi
fi

# 2. Start Cloudflare Tunnel pointing to localhost:PORT
echo "🌐 Creating temporary TryCloudflare HTTPS tunnel..."
echo "🔗 Access your KinStock app from anywhere (mobile, teammates, external testers)!"
echo "--------------------------------------------------------------------------------"

cloudflared tunnel --url http://localhost:$PORT
