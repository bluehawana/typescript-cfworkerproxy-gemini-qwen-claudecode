#!/bin/bash

# CoolClaude AnyRouter - One command to start Claude with AnyRouter free tokens

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load API key from .env.local
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env.local" ]; then
    source "$SCRIPT_DIR/.env.local"
fi

# Check if API key is available
if [ -z "$ANYROUTER_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  ANYROUTER_API_KEY not found in .env.local${NC}"
    echo -e "${BLUE}💡 Please add your AnyRouter API key to .env.local${NC}"
    exit 1
fi

echo -e "${CYAN}🚀 Starting Claude with AnyRouter free tokens...${NC}"
echo -e "${GREEN}🔑 API Key: ${ANYROUTER_API_KEY:0:10}...${NC}"
echo -e "${GREEN}🌐 Base URL: https://anyrouter.top${NC}"
echo -e "${BLUE}💰 Cost: FREE tokens!${NC}"
echo ""

# Step 1: Kill any running Claude processes and clear auth
echo -e "${YELLOW}🔄 Killing existing Claude processes...${NC}"
pkill claude 2>/dev/null || true
sleep 1

echo -e "${YELLOW}🔄 Clearing cached authentication (3x)...${NC}"
claude config logout 2>/dev/null || true
claude config logout 2>/dev/null || true
claude config logout 2>/dev/null || true

# Step 2: Set environment variables for Claude CLI
export ANTHROPIC_AUTH_TOKEN="$ANYROUTER_API_KEY"
export ANTHROPIC_BASE_URL="https://anyrouter.top"

echo -e "${GREEN}✅ Environment configured for AnyRouter${NC}"
echo ""

# Start Claude CLI
claude