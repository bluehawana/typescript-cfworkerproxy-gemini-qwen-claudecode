#!/bin/bash

# Switch Claude Code to use Gemini via worker proxy

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load API key from .env.local
if [ -f .env.local ]; then
    source .env.local
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  GEMINI_API_KEY not found in .env.local${NC}"
    echo -e "${BLUE}💡 Please add your Gemini API key to .env.local${NC}"
    exit 1
fi

echo -e "${CYAN}🔄 Switching Claude Code to Gemini...${NC}"

# Create/update Claude settings
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

echo -e "${GREEN}✅ Claude Code configured for Gemini!${NC}"
echo ""
echo -e "${GREEN}🌐 Base URL:${NC} Worker Proxy → Gemini"
echo -e "${GREEN}🔑 API Key:${NC} ${GEMINI_API_KEY:0:15}..."
echo -e "${GREEN}🤖 Model:${NC} gemini-2.0-flash-exp (mapped from claude-3-5-sonnet)"
echo -e "${GREEN}💰 Cost:${NC} FREE Google AI tokens!"
echo ""
echo -e "${BLUE}💡 Now you can use Claude Code normally and it will use Gemini${NC}"