#!/bin/bash

# Force Claude Code to use free tokens without authentication

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🔧 Forcing Claude Code to use free tokens...${NC}"

# Kill any running Claude processes
pkill -f claude 2>/dev/null || true
sleep 2

# Remove all Claude authentication data
rm -rf ~/.claude* 2>/dev/null || true
rm -rf ~/.config/claude* 2>/dev/null || true
rm -rf ~/.cache/claude* 2>/dev/null || true

# Create settings that bypass authentication
mkdir -p ~/.claude
cat > ~/.claude/settings.json << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://one-balance.bluehawana.workers.dev/api/compat",
    "ANTHROPIC_API_KEY": "8cc200d2003f89e958c64a9d918c9d7924e5941d098ca68b375645232d7e8b7b",
    "ANTHROPIC_MODEL": "google-ai-studio/gemini-2.5-pro",
    "API_TIMEOUT_MS": "600000"
  },
  "auth": {
    "skipAuth": true,
    "authenticated": true
  }
}
EOF

# Set environment variables to override authentication
export ANTHROPIC_BASE_URL="https://one-balance.bluehawana.workers.dev/api/compat"
export ANTHROPIC_API_KEY="8cc200d2003f89e958c64a9d918c9d7924e5941d098ca68b375645232d7e8b7b"
export ANTHROPIC_AUTH_TOKEN="8cc200d2003f89e958c64a9d918c9d7924e5941d098ca68b375645232d7e8b7b"

echo -e "${GREEN}✅ Configuration set for free tokens${NC}"
echo -e "${BLUE}🌐 Using: one-balance system with Gemini backend${NC}"
echo -e "${YELLOW}💰 Cost: FREE (no Claude subscription needed)${NC}"
echo ""

echo -e "${CYAN}🚀 Starting Claude Code with free backend...${NC}"

# Start Claude with environment variables
env ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL" \
    ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
    ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN" \
    claude --dangerously-skip-permissions