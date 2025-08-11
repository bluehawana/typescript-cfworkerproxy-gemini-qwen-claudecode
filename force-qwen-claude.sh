#!/bin/bash

# Force Qwen Claude - Aggressive approach

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
    exit 1
fi

echo -e "${CYAN}🚀 Force starting Claude with Qwen...${NC}"

# Nuclear option - kill everything Claude related
pkill -f claude 2>/dev/null || true
sleep 2

# Remove all Claude configs
rm -rf ~/.claude* ~/.config/claude* ~/.cache/claude* 2>/dev/null || true

# Set environment variables directly
export ANTHROPIC_BASE_URL="https://claude-worker-proxy.bluehawana.workers.dev/qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"
export ANTHROPIC_API_KEY="$QWEN_API_KEY"
export ANTHROPIC_AUTH_TOKEN="$QWEN_API_KEY"

echo -e "${GREEN}🌐 Base URL: $ANTHROPIC_BASE_URL${NC}"
echo -e "${GREEN}🔑 API Key: ${QWEN_API_KEY:0:10}...${NC}"
echo ""

# Start Claude with explicit environment
env ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL" ANTHROPIC_API_KEY="$QWEN_API_KEY" claude