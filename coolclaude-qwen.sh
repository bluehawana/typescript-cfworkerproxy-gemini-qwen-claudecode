#!/bin/bash

# CoolClaude Qwen - One command to start Claude with Qwen free tokens

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
if [ -z "$QWEN_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  QWEN_API_KEY not found in .env.local${NC}"
    echo -e "${BLUE}💡 Please add your Qwen API key to .env.local${NC}"
    exit 1
fi

echo -e "${CYAN}🚀 Starting Claude with Qwen free tokens...${NC}"
echo -e "${GREEN}🔑 API Key: ${QWEN_API_KEY:0:10}...${NC}"
echo -e "${GREEN}🌐 Base URL: Worker Proxy → Qwen${NC}"
echo -e "${BLUE}💰 Cost: FREE/Cheap Alibaba Cloud tokens!${NC}"
echo ""

# Step 1: Complete Claude reset
echo -e "${YELLOW}🔄 Killing existing Claude processes...${NC}"
pkill claude 2>/dev/null || true
pkill -f "claude" 2>/dev/null || true
sleep 2

echo -e "${YELLOW}🗑️  Removing ALL Claude configuration files...${NC}"
rm -rf ~/.claude* 2>/dev/null || true
rm -rf ~/.config/claude* 2>/dev/null || true
rm -rf ~/.cache/claude* 2>/dev/null || true

echo -e "${YELLOW}🔄 Clearing cached authentication (5x)...${NC}"
claude config logout 2>/dev/null || true
claude config logout 2>/dev/null || true
claude config logout 2>/dev/null || true
claude config logout 2>/dev/null || true
claude config logout 2>/dev/null || true

# Step 2: Wake up Cloudflare worker with test call
echo -e "${YELLOW}🔥 Waking up Cloudflare worker...${NC}"
curl -s -X POST "https://claude-worker-proxy.bluehawana.workers.dev/qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation/v1/messages" \
  -H "x-api-key: $QWEN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-3-5-sonnet","messages":[{"role":"user","content":"ping"}]}' > /dev/null 2>&1 || true

# Step 3: Remove existing settings and create fresh config
echo -e "${YELLOW}🗑️  Removing existing Claude settings...${NC}"
rm -rf ~/.claude 2>/dev/null || true
mkdir -p ~/.claude

echo -e "${YELLOW}⚙️  Creating fresh Qwen configuration...${NC}"
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

# Also set environment variables as backup
export ANTHROPIC_BASE_URL="https://claude-worker-proxy.bluehawana.workers.dev/qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"
export ANTHROPIC_API_KEY="$QWEN_API_KEY"

echo -e "${GREEN}✅ Environment configured for Qwen${NC}"
echo ""

# Start Claude CLI
claude