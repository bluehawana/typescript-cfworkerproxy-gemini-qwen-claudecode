#!/bin/bash

# Switch Claude Code to use AnyRouter directly

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

if [ -z "$ANYROUTER_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  ANYROUTER_API_KEY not found in .env.local${NC}"
    echo -e "${BLUE}💡 Please add your AnyRouter API key to .env.local${NC}"
    exit 1
fi

echo -e "${CYAN}🔄 Switching Claude Code to AnyRouter...${NC}"

# Create/update Claude settings
mkdir -p ~/.claude

cat > ~/.claude/settings.json << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://anyrouter.top",
    "ANTHROPIC_API_KEY": "$ANYROUTER_API_KEY",
    "ANTHROPIC_MODEL": "claude-3-5-sonnet-20241022",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-3-5-sonnet-20241022",
    "API_TIMEOUT_MS": "600000"
  }
}
EOF

echo -e "${GREEN}✅ Claude Code configured for AnyRouter!${NC}"
echo ""
echo -e "${GREEN}🌐 Base URL:${NC} https://anyrouter.top"
echo -e "${GREEN}🔑 API Key:${NC} ${ANYROUTER_API_KEY:0:10}..."
echo -e "${GREEN}🤖 Model:${NC} claude-3-5-sonnet-20241022"
echo -e "${GREEN}💰 Cost:${NC} FREE/Cheap tokens!"
echo ""
echo -e "${BLUE}💡 Now you can use Claude Code normally and it will use AnyRouter${NC}"