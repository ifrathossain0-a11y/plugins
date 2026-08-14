#!/bin/bash
# OmniRoute One-Command Setup Script
# Run with:  bash <(curl -sL URL)
# This keeps stdin available so the script can ask for your API key.

set -euo pipefail

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
    if [ ! -f /etc/debian_version ]; then
        echo "       ERROR: This script is designed for Ubuntu/Debian servers."
        echo "       Please install Node.js 22 manually, then re-run this script."
        exit 1
    fi
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y -qq curl > /dev/null 2>&1
    curl -fsSL https://deb.nodesource.com/setup_22.x -o /tmp/nodesource_setup.sh
    bash /tmp/nodesource_setup.sh > /dev/null 2>&1
    apt-get install -y -qq nodejs > /dev/null 2>&1
    rm -f /tmp/nodesource_setup.sh
    if ! command -v node &> /dev/null; then
        echo "       ERROR: Node.js installation failed."
        echo "       Try manually: https://nodejs.org/en/download"
        exit 1
    fi
    echo "       Installed Node.js $(node --version)"
fi

# --- 2. Install OmniRoute ---
echo "[2/5] Installing OmniRoute (this takes about a minute)..."
npm install -g omniroute 2>&1 | tail -1 || true
if ! command -v omniroute &> /dev/null; then
    echo "       ERROR: OmniRoute installation failed."
    exit 1
fi
echo "       Installed OmniRoute $(omniroute --version 2>/dev/null | head -1)"

# --- 3. Ask for OpenRouter key ---
echo ""
echo "[3/5] Connect OpenRouter (1,000+ free AI models)"
echo ""
echo "       Get a free key at: https://openrouter.ai/keys"
echo ""

OPENROUTER_KEY=""
if [ -t 0 ]; then
    read -p "       Paste your OpenRouter API key (or press Enter to skip): " OPENROUTER_KEY
    echo ""
else
    echo "       NOTE: Cannot prompt for key (stdin is piped)."
    echo "       Re-run with:  bash <(curl -sL THE_URL)"
    echo "       Or add it later from the dashboard."
    echo ""
fi

if [ -z "$OPENROUTER_KEY" ]; then
    echo "       Skipped — you can add it later from the dashboard."
else
    echo "       Key saved. Will connect after server starts."
fi

# --- 4. Start OmniRoute ---
echo "[4/5] Starting OmniRoute..."

# Check if something is already running on port 20128
if curl -s -o /dev/null -w "%{http_code}" http://localhost:20128/v1/models 2>/dev/null | grep -q "200"; then
    echo "       OmniRoute is already running on port 20128."
else
    # Try systemd first (most Ubuntu VPS)
    if command -v systemctl &> /dev/null && systemctl is-system-running &> /dev/null; then
        OMNIROUTE_BIN=$(which omniroute)
        cat > /etc/systemd/system/omniroute.service << UNIT
[Unit]
Description=OmniRoute AI Gateway
After=network.target

[Service]
Type=simple
ExecStart=${OMNIROUTE_BIN} serve
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
UNIT

        systemctl daemon-reload
        systemctl enable omniroute > /dev/null 2>&1
        systemctl start omniroute
        echo "       Started with systemd (auto-restarts on reboot)."
    else
        # Fallback: run in background with nohup
        nohup omniroute serve > /var/log/omniroute.log 2>&1 &
        echo "       Started in background (PID: $!)."
        echo "       Log: /var/log/omniroute.log"
        echo ""
        echo "       TIP: To auto-start on reboot, add this to /etc/rc.local:"
        echo "         nohup omniroute serve > /var/log/omniroute.log 2>&1 &"
    fi

    # Wait for server to be ready
    echo "       Waiting for server to start..."
    READY=false
    for i in $(seq 1 30); do
        if curl -s -o /dev/null http://localhost:20128/v1/models 2>/dev/null; then
            READY=true
            break
        fi
        sleep 2
    done

    if [ "$READY" = false ]; then
        echo ""
        echo "       WARNING: Server didn't respond within 60 seconds."
        echo "       It may still be starting. Check with:"
        echo "         curl http://localhost:20128/v1/models"
        echo ""
    else
        echo "       Server is running!"
    fi
fi

# --- 5. Connect OpenRouter if key was provided ---
if [ -n "$OPENROUTER_KEY" ]; then
    echo "[5/5] Connecting OpenRouter..."

    # Login to get auth cookie
    LOGIN_OK=$(curl -s -c /tmp/omni-cookies.txt -X POST http://localhost:20128/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"password": "CHANGEME"}' 2>&1)

    if echo "$LOGIN_OK" | grep -q '"success":true'; then
        # Add OpenRouter provider
        RESULT=$(curl -s -b /tmp/omni-cookies.txt -X POST http://localhost:20128/api/providers \
            -H "Content-Type: application/json" \
            -d "{\"provider\": \"openrouter\", \"name\": \"OpenRouter\", \"apiKey\": \"$OPENROUTER_KEY\"}" 2>&1)

        if echo "$RESULT" | grep -q '"connection"'; then
            # Count models
            MODEL_COUNT=$(curl -s http://localhost:20128/v1/models 2>/dev/null \
                | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('data',[])))" 2>/dev/null \
                || echo "many")
            echo "       OpenRouter connected! $MODEL_COUNT models available."
        else
            echo "       Could not connect automatically."
            echo "       Open the dashboard and add OpenRouter from there."
        fi
    else
        echo "       Could not log into dashboard."
        echo "       Open the dashboard and add OpenRouter manually."
    fi

    rm -f /tmp/omni-cookies.txt
else
    echo "[5/5] Skipped provider setup."
fi

# --- Done ---
SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null \
    || curl -s --max-time 5 icanhazip.com 2>/dev/null \
    || hostname -I 2>/dev/null | awk '{print $1}' \
    || echo "YOUR-SERVER-IP")

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
if command -v systemctl &> /dev/null && systemctl is-enabled omniroute &> /dev/null 2>&1; then
    echo "  OmniRoute starts automatically on reboot."
    echo "  To stop:    systemctl stop omniroute"
    echo "  To restart: systemctl restart omniroute"
else
    echo "  To stop:    pkill -f 'omniroute serve'"
    echo "  To restart: nohup omniroute serve > /var/log/omniroute.log 2>&1 &"
fi
echo ""
