#!/bin/bash

# Claude with One-Balance - Production AI proxy

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 Starting Claude with One-Balance Production System${NC}"
echo -e "${GREEN}🌐 URL: https://one-balance.bluehawana.workers.dev${NC}"
echo -e "${GREEN}🔐 AUTH_KEY: 8cc200d2003f89e958c64a9d918c9d7924e59...${NC}"
echo ""

# Kill existing Claude processes
pkill claude 2>/dev/null || true
sleep 1

# Remove old settings
rm -rf ~/.claude* 2>/dev/null || true

# Configure Claude Code for one-balance
mkdir -p ~/.claude
cat > ~/.claude/settings.json << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://one-balance.bluehawana.workers.dev/api/compat",
    "ANTHROPIC_API_KEY": "8cc200d2003f89e958c64a9d918c9d7924e59e4c2b8b6c9f7a3d1e5f8b2c4a6d9",
    "ANTHROPIC_MODEL": "google-ai-studio/gemini-2.5-pro",
    "API_TIMEOUT_MS": "600000"
  }
}
EOF

echo -e "${GREEN}✅ Claude configured for one-balance system${NC}"
echo ""

# Start Claude
claude