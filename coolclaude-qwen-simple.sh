#!/bin/bash

# CoolClaude Qwen Simple - Clean switch to Qwen

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

echo -e "${CYAN}🚀 Switching to Qwen...${NC}"

# Kill any running Claude processes
pkill claude 2>/dev/null || true
sleep 2

# Clear Claude settings completely
rm -rf ~/.claude 2>/dev/null || true
mkdir -p ~/.claude

# Create fresh Qwen configuration
cat > ~/.claude/settings.json << 'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://claude-worker-proxy.bluehawana.workers.dev/qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation",
    "ANTHROPIC_API_KEY": "QWEN_KEY_PLACEHOLDER",
    "ANTHROPIC_MODEL": "claude-3-5-sonnet",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-3-5-sonnet",
    "API_TIMEOUT_MS": "600000"
  }
}
EOF

# Replace placeholder with actual key
sed -i '' "s/QWEN_KEY_PLACEHOLDER/$QWEN_API_KEY/g" ~/.claude/settings.json

echo -e "${GREEN}✅ Configured for Qwen${NC}"
echo -e "${GREEN}🔑 API Key: ${QWEN_API_KEY:0:10}...${NC}"
echo ""

# Start Claude
claude