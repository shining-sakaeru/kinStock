#!/usr/bin/env bash
# ==============================================================================
# KinStock All-in-One One-Click Deployment Script
# Target: Oracle Cloud Always Free (ARM64 Ubuntu) or Local Docker Host
# ==============================================================================

set -e

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}"
echo "======================================================================"
echo "   🚀 KinStock All-in-One Deployment (Oracle Cloud ARM64 / Docker)   "
echo "======================================================================"
echo -e "${NC}"

# 1. System & Architecture Detection
ARCH=$(uname -m)
OS=$(uname -s)
echo -e "${BLUE}ℹ️  System Architecture:${NC} $OS ($ARCH)"

# 2. Check Docker & Docker Compose
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker is not installed.${NC}"
    if [ "$OS" = "Linux" ] && [ -f /etc/debian_version ]; then
        echo -e "${GREEN}🔄 Automatically installing Docker on Ubuntu/Debian ARM64...${NC}"
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose
        sudo usermod -aG docker "$USER" || true
        echo -e "${GREEN}✅ Docker installed successfully!${NC}"
    else
        echo -e "${RED}❌ Please install Docker and Docker Compose before running this script.${NC}"
        exit 1
    fi
fi

# Determine compose command
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo -e "${RED}❌ Docker Compose plugin or binary not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Using Compose Engine:${NC} $COMPOSE_CMD"

# Ensure data directories exist
mkdir -p data/neo4j/import

# 3. Optional local Flutter Web build for fast packaging
if command -v flutter &> /dev/null; then
    echo -e "${BLUE}📦 Building Flutter Web locally for optimized Docker image...${NC}"
    (cd frontend && flutter build web --release --pwa-strategy=none)
    echo -e "${GREEN}✅ Flutter Web build finished!${NC}"
else
    echo -e "${YELLOW}ℹ️  Local Flutter SDK not detected. Docker multi-stage build will compile Flutter Web inside container.${NC}"
fi

# 4. Docker Compose Build & Launch
echo -e "${BLUE}🐳 Starting Docker Compose stack (Neo4j, FastAPI, Flutter Nginx, Cloudflare)...${NC}"
$COMPOSE_CMD down || true
$COMPOSE_CMD up -d --build

echo -e "${CYAN}⏳ Waiting for services to initialize...${NC}"
sleep 6

# 5. Extract Cloudflare Quick Tunnel URL
echo -e "${CYAN}🔍 Extracting Cloudflare Tunnel public HTTPS URL...${NC}"
PUBLIC_URL=""
for i in {1..30}; do
    LOGS=$($COMPOSE_CMD logs cloudflare-tunnel 2>&1 || true)
    URL=$(echo "$LOGS" | grep -o 'https://[-a-zA-Z0-9@:%._\+~#=]*.trycloudflare.com' | tail -n 1 || true)
    if [ -n "$URL" ]; then
        PUBLIC_URL="$URL"
        break
    fi
    sleep 2
done

echo ""
echo -e "${GREEN}${BOLD}======================================================================${NC}"
echo -e "${GREEN}${BOLD}   🎉 KinStock All-in-One Service Successfully Deployed!             ${NC}"
echo -e "${GREEN}${BOLD}======================================================================${NC}"
echo ""

if [ -n "$PUBLIC_URL" ]; then
    echo -e "${YELLOW}${BOLD}🌐 Public HTTPS URL (Cloudflare Tunnel):${NC}"
    echo -e "   👉 ${BOLD}${CYAN}${PUBLIC_URL}${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠️  Cloudflare Tunnel URL is initializing. Run '$COMPOSE_CMD logs cloudflare-tunnel' in a few seconds.${NC}"
    echo ""
fi

echo -e "${BOLD}📍 Local & Management Endpoints:${NC}"
echo -e "   - 📱 Frontend Web App:     ${GREEN}http://localhost:80${NC} (or http://localhost:3000)"
echo -e "   - ⚙️  FastAPI Swagger Docs: ${GREEN}http://localhost:8000/docs${NC} (or http://localhost/docs)"
echo -e "   - 🗄️  Neo4j Browser:        ${GREEN}http://localhost:7474${NC} (user: neo4j, pass: kinstock2024!)"
echo ""
echo -e "${BOLD}📋 Management Commands:${NC}"
echo -e "   - View live logs:          ${CYAN}$COMPOSE_CMD logs -f${NC}"
echo -e "   - View Tunnel URL:         ${CYAN}$COMPOSE_CMD logs cloudflare-tunnel${NC}"
echo -e "   - Stop all services:       ${CYAN}$COMPOSE_CMD down${NC}"
echo -e "   - Restart all services:    ${CYAN}$COMPOSE_CMD restart${NC}"
echo ""
echo -e "${GREEN}======================================================================${NC}"
