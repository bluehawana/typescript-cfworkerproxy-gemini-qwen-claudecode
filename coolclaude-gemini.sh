#!/bin/bash

# CoolClaude Gemini - One command to start Claude with Gemini free tokens

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
if [ -z "$GEMINI_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  GEMINI_API_KEY not found in .env.local${NC}"
    echo -e "${BLUE}💡 Please add your Gemini API key to .env.local${NC}"
    exit 1
fi

echo -e "${CYAN}🚀 Starting Claude with Gemini free tokens...${NC}"
echo -e "${GREEN}🔑 API Key: ${GEMINI_API_KEY:0:15}...${NC}"
echo -e "${GREEN}🌐 Base URL: Worker Proxy → Gemini${NC}"
echo -e "${BLUE}💰 Cost: FREE Google AI tokens!${NC}"
echo ""

# Step 1: Kill any running Claude processes and clear auth
echo -e "${YELLOW}🔄 Killing existing Claude processes...${NC}"
pkill claude 2>/dev/null || true
sleep 1

echo -e "${YELLOW}🔄 Clearing cached authentication (3x)...${NC}"
claude config logout 2>/dev/null || true
claude config logout 2>/dev/null || true
claude config logout 2>/dev/null || true

# Step 2: Wake up Cloudflare worker with test call
echo -e "${YELLOW}🔥 Waking up Cloudflare worker...${NC}"
curl -s -X POST "https://claude-worker-proxy.bluehawana.workers.dev/gemini/generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent/v1/messages" \
  -H "x-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-3-5-sonnet","messages":[{"role":"user","content":"ping"}]}' > /dev/null 2>&1 || true

# Step 3: Configure Claude Code to use Gemini via worker proxy
mkdir -p ~/.claude
cat > ~/.claude/settings.json << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://claude-worker-proxy.bluehawana.workers.dev/gemini/generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent",
    "ANTHROPIC_API_KEY": "$GEMINI_API_KEY",
    "ANTHROPIC_MODEL": "claude-3-5-sonnet",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-3-5-sonnet",
    "API_TIMEOUT_MS": "600000"
  }
}
EOF

echo -e "${GREEN}✅ Environment configured for Gemini${NC}"
echo ""

# Start Claude CLI
claude