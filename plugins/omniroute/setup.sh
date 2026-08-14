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

# --- 0. Check we're running as root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "  ERROR: Please run this script as root."
    echo "  Try:   sudo bash <(curl -sL THE_URL)"
    exit 1
fi

# --- 1. Install Node.js ---
echo "[1/6] Installing Node.js..."
if command -v node &> /dev/null; then
    echo "       Node.js already installed: $(node --version)"
else
    if [ ! -f /etc/debian_version ]; then
        echo "       ERROR: This script is designed for Ubuntu/Debian servers."
        echo "       Please install Node.js 22 manually, then re-run this script."
        exit 1
    fi
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y -qq curl ca-certificates gnupg > /dev/null 2>&1
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
echo "[2/6] Installing OmniRoute (this takes 1-3 minutes)..."

# Add swap if less than 1.5GB RAM available (npm needs memory)
AVAIL_MEM=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo "2048")
if [ "$AVAIL_MEM" -lt 1500 ] && [ ! -f /swapfile ]; then
    echo "       Low memory detected (${AVAIL_MEM}MB). Adding swap..."
    fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
    chmod 600 /swapfile
    mkswap /swapfile > /dev/null 2>&1
    swapon /swapfile 2>/dev/null || true
    echo "       Swap added."
fi

npm install -g omniroute 2>&1 | tail -1 || true
if ! command -v omniroute &> /dev/null; then
    echo "       ERROR: OmniRoute installation failed."
    echo "       Try running manually: npm install -g omniroute"
    exit 1
fi
echo "       Installed OmniRoute $(omniroute --version 2>/dev/null | head -1)"

# --- 3. Ask for OpenRouter key ---
echo ""
echo "[3/6] Connect OpenRouter (1,000+ free AI models)"
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

# --- 4. Set a dashboard password ---
echo ""
echo "[4/6] Dashboard password"

ADMIN_PASS=""
if [ -t 0 ]; then
    echo "       The dashboard lets you manage models and providers."
    echo "       Anyone with your server IP can reach it, so set a password."
    echo ""
    read -sp "       Choose a password (or Enter for 'omniroute'): " ADMIN_PASS
    echo ""
fi

if [ -z "$ADMIN_PASS" ]; then
    ADMIN_PASS="omniroute"
    echo "       Using default password: omniroute"
fi

# Write password to OmniRoute env
OMNIROUTE_DIR="/root/.omniroute"
mkdir -p "$OMNIROUTE_DIR"
if [ -f "$OMNIROUTE_DIR/.env" ]; then
    # Replace existing INITIAL_PASSWORD if present
    if grep -q "^INITIAL_PASSWORD=" "$OMNIROUTE_DIR/.env" 2>/dev/null; then
        sed -i "s/^INITIAL_PASSWORD=.*/INITIAL_PASSWORD=$ADMIN_PASS/" "$OMNIROUTE_DIR/.env"
    else
        echo "INITIAL_PASSWORD=$ADMIN_PASS" >> "$OMNIROUTE_DIR/.env"
    fi
else
    echo "INITIAL_PASSWORD=$ADMIN_PASS" > "$OMNIROUTE_DIR/.env"
fi

# Also set it in the main env file that OmniRoute reads
OMNIROUTE_PKG_DIR=$(npm root -g)/omniroute
if [ -f "$OMNIROUTE_PKG_DIR/.env" ]; then
    sed -i "s/^INITIAL_PASSWORD=.*/INITIAL_PASSWORD=$ADMIN_PASS/" "$OMNIROUTE_PKG_DIR/.env"
fi

# --- 5. Open firewall and start OmniRoute ---
echo "[5/6] Starting OmniRoute..."

# Open port 20128 in firewall
if command -v ufw &> /dev/null; then
    ufw allow 20128/tcp > /dev/null 2>&1 || true
    echo "       Opened port 20128 in firewall (ufw)."
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=20128/tcp > /dev/null 2>&1 || true
    firewall-cmd --reload > /dev/null 2>&1 || true
    echo "       Opened port 20128 in firewall (firewalld)."
else
    echo "       No firewall detected. Port 20128 should be open."
    echo "       If you can't connect, check your VPS provider's firewall settings."
fi

# Check if something is already running on port 20128
if curl -s -o /dev/null -w "%{http_code}" http://localhost:20128/v1/models 2>/dev/null | grep -q "200"; then
    echo "       OmniRoute is already running on port 20128."
else
    # Try systemd first (most Ubuntu VPS)
    if command -v systemctl &> /dev/null && systemctl is-system-running &> /dev/null; then
        OMNIROUTE_BIN=$(which omniroute)
        NODE_BIN=$(which node)
        cat > /etc/systemd/system/omniroute.service << UNIT
[Unit]
Description=OmniRoute AI Gateway
After=network.target

[Service]
Type=simple
ExecStart=${NODE_BIN} ${OMNIROUTE_BIN} serve
Restart=always
RestartSec=5
Environment=NODE_ENV=production
WorkingDirectory=/root

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
        OMNI_PID=$!
        echo "       Started in background (PID: $OMNI_PID)."
        echo "       Log: /var/log/omniroute.log"
    fi

    # Wait for server to be ready
    echo "       Waiting for server to start..."
    READY=false
    for i in $(seq 1 45); do
        if curl -s -o /dev/null http://localhost:20128/v1/models 2>/dev/null; then
            READY=true
            break
        fi
        sleep 2
    done

    if [ "$READY" = false ]; then
        echo ""
        echo "       WARNING: Server didn't respond within 90 seconds."
        echo "       It may still be starting. Check with:"
        echo "         curl http://localhost:20128/v1/models"
        echo ""
    else
        echo "       Server is running!"
    fi
fi

# --- 6. Connect OpenRouter if key was provided ---
if [ -n "$OPENROUTER_KEY" ]; then
    echo "[6/6] Connecting OpenRouter..."

    # Login to get auth cookie
    LOGIN_OK=$(curl -s -c /tmp/omni-cookies.txt -X POST http://localhost:20128/api/auth/login \
        -H "Content-Type: application/json" \
        -d "{\"password\": \"$ADMIN_PASS\"}" 2>&1)

    if echo "$LOGIN_OK" | grep -q '"success":true'; then
        # Add OpenRouter provider
        RESULT=$(curl -s -b /tmp/omni-cookies.txt -X POST http://localhost:20128/api/providers \
            -H "Content-Type: application/json" \
            -d "{\"provider\": \"openrouter\", \"name\": \"OpenRouter\", \"apiKey\": \"$OPENROUTER_KEY\"}" 2>&1)

        if echo "$RESULT" | grep -q '"connection"'; then
            # Count models
            sleep 2
            MODEL_COUNT=$(curl -s http://localhost:20128/v1/models 2>/dev/null \
                | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('data',[])))" 2>/dev/null \
                || echo "many")
            echo "       OpenRouter connected! $MODEL_COUNT models available."
        else
            echo "       Could not connect automatically."
            echo "       Open the dashboard and add OpenRouter from there."
        fi
    else
        # Try with default password in case env wasn't picked up yet
        LOGIN_OK=$(curl -s -c /tmp/omni-cookies.txt -X POST http://localhost:20128/api/auth/login \
            -H "Content-Type: application/json" \
            -d '{"password": "CHANGEME"}' 2>&1)

        if echo "$LOGIN_OK" | grep -q '"success":true'; then
            RESULT=$(curl -s -b /tmp/omni-cookies.txt -X POST http://localhost:20128/api/providers \
                -H "Content-Type: application/json" \
                -d "{\"provider\": \"openrouter\", \"name\": \"OpenRouter\", \"apiKey\": \"$OPENROUTER_KEY\"}" 2>&1)

            if echo "$RESULT" | grep -q '"connection"'; then
                sleep 2
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
            echo "       Open http://YOUR-IP:20128 and add OpenRouter manually."
        fi
    fi

    rm -f /tmp/omni-cookies.txt
else
    echo "[6/6] Skipped provider setup."
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
echo "  Password:   $ADMIN_PASS"
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
echo "  IMPORTANT: If you can't reach the dashboard from your phone,"
echo "  check your VPS provider's firewall. You may need to allow"
echo "  port 20128 in their web console (not just ufw)."
echo ""
