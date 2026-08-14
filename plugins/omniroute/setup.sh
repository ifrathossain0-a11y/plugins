#!/bin/bash
# OmniRoute One-Command Setup Script
# Paste this into your server terminal and everything installs automatically.

set -e

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     OmniRoute — Automatic Setup      ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# --- 1. Install Node.js ---
echo "[1/5] Installing Node.js..."
if command -v node &> /dev/null; then
    echo "       Node.js already installed: $(node --version)"
else
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1
    apt-get install -y nodejs > /dev/null 2>&1
    echo "       Installed Node.js $(node --version)"
fi

# --- 2. Install OmniRoute ---
echo "[2/5] Installing OmniRoute (this takes about a minute)..."
npm install -g omniroute > /dev/null 2>&1
echo "       Installed OmniRoute $(omniroute --version)"

# --- 3. Ask for OpenRouter key ---
echo ""
echo "[3/5] Connect OpenRouter (1,000+ free AI models)"
echo ""
echo "       Get a free key at: https://openrouter.ai/keys"
echo ""
read -p "       Paste your OpenRouter API key: " OPENROUTER_KEY
echo ""

if [ -z "$OPENROUTER_KEY" ]; then
    echo "       Skipped — you can add it later from the dashboard."
else
    echo "       Key saved. Will connect after server starts."
fi

# --- 4. Start OmniRoute as a background service ---
echo "[4/5] Starting OmniRoute..."

# Create systemd service for auto-start on reboot
cat > /etc/systemd/system/omniroute.service << 'UNIT'
[Unit]
Description=OmniRoute AI Gateway
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/env omniroute serve
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable omniroute > /dev/null 2>&1
systemctl start omniroute

# Wait for server to be ready
echo "       Waiting for server to start..."
for i in {1..30}; do
    if curl -s http://localhost:20128/api/health > /dev/null 2>&1; then
        break
    fi
    sleep 2
done

echo "       Server is running!"

# --- 5. Connect OpenRouter if key was provided ---
if [ -n "$OPENROUTER_KEY" ]; then
    echo "[5/5] Connecting OpenRouter..."

    # Login to get auth cookie
    curl -s -c /tmp/omni-cookies.txt -X POST http://localhost:20128/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"password": "CHANGEME"}' > /dev/null 2>&1

    # Add OpenRouter provider
    RESULT=$(curl -s -b /tmp/omni-cookies.txt -X POST http://localhost:20128/api/providers \
        -H "Content-Type: application/json" \
        -d "{\"provider\": \"openrouter\", \"name\": \"OpenRouter\", \"apiKey\": \"$OPENROUTER_KEY\"}" 2>&1)

    if echo "$RESULT" | grep -q '"connection"'; then
        echo "       OpenRouter connected!"
    else
        echo "       Could not connect automatically. Add it from the dashboard."
    fi

    rm -f /tmp/omni-cookies.txt
else
    echo "[5/5] Skipped provider setup."
fi

# --- Done ---
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║           Setup Complete!            ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
echo "  Dashboard:  http://$SERVER_IP:20128"
echo "  API:        http://$SERVER_IP:20128/v1"
echo ""
echo "  Quick start:"
echo "    omniroute chat                    # Start chatting"
echo "    omniroute chat \"your question\"    # Quick question"
echo "    omniroute models                  # See all models"
echo "    omniroute quota                   # Check usage"
echo ""
echo "  OmniRoute starts automatically on reboot."
echo "  To stop:    systemctl stop omniroute"
echo "  To restart: systemctl restart omniroute"
echo ""
