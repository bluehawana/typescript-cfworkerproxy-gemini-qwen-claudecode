#!/bin/bash

# Switch Claude Code to use Qwen via worker proxy

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

if [ -z "$QWEN_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  QWEN_API_KEY not found in .env.local${NC}"
    echo -e "${BLUE}💡 Please add your Qwen API key to .env.local${NC}"
    exit 1
fi

echo -e "${CYAN}🔄 Switching Claude Code to Qwen...${NC}"

# Create/update Claude settings
mkdir -p ~/.claude

cat > ~/.claude/settings.json << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://claude-worker-proxy.bluehawana.workers.dev/qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation",
    "ANTHROPIC_API_KEY": "$QWEN_API_KEY",
    "ANTHROPIC_MODEL": "claude-3-5-sonnet",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-3-5-sonnet",
    "API_TIMEOUT_MS": "600000"
  }
}
EOF

echo -e "${GREEN}✅ Claude Code configured for Qwen!${NC}"
echo ""
echo -e "${GREEN}🌐 Base URL:${NC} Worker Proxy → Qwen"
echo -e "${GREEN}🔑 API Key:${NC} ${QWEN_API_KEY:0:10}..."
echo -e "${GREEN}🤖 Model:${NC} qwen-max (mapped from claude-3-5-sonnet)"
echo -e "${GREEN}💰 Cost:${NC} FREE/Cheap Alibaba Cloud tokens!"
echo ""
echo -e "${BLUE}💡 Now you can use Claude Code normally and it will use Qwen${NC}"