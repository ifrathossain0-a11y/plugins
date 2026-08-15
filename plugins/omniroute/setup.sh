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

# Detect server IP early — needed for DNS verification later
SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null \
    || curl -s --max-time 5 icanhazip.com 2>/dev/null \
    || hostname -I 2>/dev/null | awk '{print $1}' \
    || echo "YOUR-SERVER-IP")

# --- 1. Install Node.js ---
echo "[1/7] Installing Node.js..."
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
echo "[2/7] Installing OmniRoute (this takes 1-3 minutes)..."

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
echo "[3/7] Connect OpenRouter (1,000+ free AI models)"
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
echo "[4/7] Dashboard password"

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
echo "[5/7] Starting OmniRoute..."

# Open ports in firewall: 20128 for the API/dashboard, 80+443 for HTTPS (step 7)
if command -v ufw &> /dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
    ufw allow 20128/tcp > /dev/null 2>&1 || true
    ufw allow 80/tcp > /dev/null 2>&1 || true
    ufw allow 443/tcp > /dev/null 2>&1 || true
    echo "       Opened ports 20128, 80, 443 in firewall (ufw)."
elif command -v firewall-cmd &> /dev/null && systemctl is-active firewalld &> /dev/null; then
    firewall-cmd --permanent --add-port=20128/tcp > /dev/null 2>&1 || true
    firewall-cmd --permanent --add-port=80/tcp > /dev/null 2>&1 || true
    firewall-cmd --permanent --add-port=443/tcp > /dev/null 2>&1 || true
    firewall-cmd --reload > /dev/null 2>&1 || true
    echo "       Opened ports 20128, 80, 443 in firewall (firewalld)."
elif command -v iptables &> /dev/null; then
    # Covers Oracle Cloud's default Ubuntu image, which ships with raw
    # iptables rules (no ufw/firewalld) that block everything but SSH.
    IPT_CHANGED=false
    for PORT in 20128 80 443; do
        if ! iptables -C INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; then
            iptables -I INPUT 1 -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null || true
            IPT_CHANGED=true
        fi
    done
    if [ "$IPT_CHANGED" = true ]; then
        # Persist across reboot so the rules survive
        if command -v netfilter-persistent &> /dev/null; then
            netfilter-persistent save > /dev/null 2>&1 || true
        elif [ -d /etc/iptables ]; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
        echo "       Opened ports 20128, 80, 443 directly in iptables."
    else
        echo "       Ports 20128, 80, 443 already allowed in iptables."
    fi
else
    echo "       No firewall tool detected. Ports should be open at the OS level."
fi

echo "       Note: your VPS provider may ALSO have its own separate cloud"
echo "       firewall (e.g. Oracle Cloud's Security Lists, DigitalOcean's"
echo "       Networking > Firewalls). Open ports 20128, 80, 443 there too —"
echo "       this step only handles the server's own OS firewall."

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
    echo "[6/7] Connecting OpenRouter..."

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
    echo "[6/7] Skipped provider setup."
fi

# --- 7. Optional: HTTPS domain (needed for OpenAI custom provider, ChatGPT apps, etc.) ---
echo ""
echo "[7/7] HTTPS domain (optional)"
echo ""
echo "       Some tools (e.g. OpenAI's custom model provider, ChatGPT apps)"
echo "       require an https:// endpoint — plain IP:port won't work there."
echo "       Free domains: duckdns.org, afraid.org, or use your own."
echo ""

DOMAIN=""
if [ -t 0 ]; then
    echo "       Point your domain's A record at this server's IP first: $SERVER_IP"
    echo ""
    read -p "       Domain name (e.g. myroute.duckdns.org), or Enter to skip: " DOMAIN
    echo ""
else
    echo "       NOTE: Cannot prompt for a domain (stdin is piped)."
    echo "       Re-run interactively to set up HTTPS, or run this later:"
    echo "         bash <(curl -sL THE_URL)"
    echo ""
fi

HTTPS_URL=""
if [ -n "$DOMAIN" ]; then
    echo "       Checking DNS for $DOMAIN..."

    DOMAIN_IP=$(curl -s --max-time 8 "https://dns.google/resolve?name=${DOMAIN}&type=A" 2>/dev/null \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Answer'][0]['data'] if 'Answer' in d else '')" 2>/dev/null || echo "")

    if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
        echo "       WARNING: $DOMAIN does not point to this server yet."
        echo "       DNS currently resolves to: ${DOMAIN_IP:-nothing}"
        echo "       Expected: $SERVER_IP"
        echo ""
        echo "       Update your domain's DNS A record, wait a few minutes for it"
        echo "       to propagate, then re-run this script to finish HTTPS setup."
    else
        echo "       DNS confirmed. Installing Caddy for automatic HTTPS..."

        if [ -f /etc/debian_version ]; then
            apt-get install -y -qq debian-keyring debian-archive-keyring apt-transport-https gnupg > /dev/null 2>&1
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
                | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg 2>/dev/null
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
                | tee /etc/apt/sources.list.d/caddy-stable.list > /dev/null
            apt-get update -qq > /dev/null 2>&1
            apt-get install -y -qq caddy > /dev/null 2>&1
        fi

        if ! command -v caddy &> /dev/null; then
            echo "       ERROR: Caddy installation failed. HTTPS not configured."
            echo "       You can still use http://$SERVER_IP:20128/v1 directly."
        else
            mkdir -p /etc/caddy
            cat > /etc/caddy/Caddyfile << CADDYCFG
${DOMAIN} {
    reverse_proxy localhost:20128
}
CADDYCFG

            if command -v systemctl &> /dev/null && systemctl is-system-running &> /dev/null; then
                systemctl enable caddy > /dev/null 2>&1
                systemctl restart caddy
            else
                pkill -f "caddy run" 2>/dev/null || true
                sleep 1
                nohup caddy run --config /etc/caddy/Caddyfile > /var/log/caddy.log 2>&1 &
            fi

            echo "       Waiting for certificate (usually 10-30 seconds)..."
            CERT_READY=false
            for i in $(seq 1 20); do
                if curl -s -o /dev/null --max-time 5 "https://${DOMAIN}/v1/models" 2>/dev/null; then
                    CERT_READY=true
                    break
                fi
                sleep 3
            done

            if [ "$CERT_READY" = true ]; then
                HTTPS_URL="https://${DOMAIN}"
                echo "       HTTPS is live: https://${DOMAIN}/v1"
            else
                CADDY_LOG="/var/log/caddy.log"
                if [ ! -f "$CADDY_LOG" ] && command -v journalctl &> /dev/null; then
                    journalctl -u caddy -n 50 --no-pager > /tmp/caddy-journal.log 2>/dev/null
                    CADDY_LOG="/tmp/caddy-journal.log"
                fi

                if [ -f "$CADDY_LOG" ] && grep -qi "firewall problem\|timeout during connect" "$CADDY_LOG" 2>/dev/null; then
                    echo "       Certificate request failed: your VPS provider is blocking"
                    echo "       inbound traffic on port 80 and/or 443."
                    echo ""
                    echo "       Fix: open ports 80 and 443 in your VPS provider's web"
                    echo "       console (their network firewall, separate from ufw —"
                    echo "       e.g. DigitalOcean 'Networking > Firewalls', Hetzner"
                    echo "       'Firewalls', Vultr 'Firewall'). Then re-run this script."
                    echo ""
                    echo "       Caddy will also keep retrying automatically every"
                    echo "       60 seconds once the ports are reachable — no need to"
                    echo "       restart it once you fix the firewall."
                else
                    echo "       Caddy is running but the certificate isn't ready yet."
                    echo "       Caddy retries automatically. Check back in a minute:"
                    echo "         curl https://${DOMAIN}/v1/models"
                fi
            fi
        fi
    fi
else
    echo "       Skipped — using http://$SERVER_IP:20128 only."
fi

# --- Done ---
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║           Setup Complete!            ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
echo "  Dashboard:  http://$SERVER_IP:20128"
echo "  Password:   $ADMIN_PASS"
echo "  API:        http://$SERVER_IP:20128/v1"
if [ -n "$HTTPS_URL" ]; then
    echo "  HTTPS API:  $HTTPS_URL/v1"
fi
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
echo "  ports 20128, 80, and 443 in their web console (not just ufw)."
echo ""
