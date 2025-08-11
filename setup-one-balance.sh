#!/bin/bash

# Setup One-Balance - Production-ready AI proxy system

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🚀 Setting up One-Balance Production System${NC}"
echo -e "${GREEN}📖 Based on: https://github.com/glidea/one-balance${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f ".env.local" ]; then
    echo -e "${RED}❌ Please run this from the claude-worker-proxy directory${NC}"
    exit 1
fi

# Load existing API keys
source .env.local

echo -e "${YELLOW}📋 Current API Keys:${NC}"
echo "AnyRouter: ${ANYROUTER_API_KEY:0:10}..."
echo "Gemini: ${GEMINI_API_KEY:0:15}..."
echo "Qwen: ${QWEN_API_KEY:0:10}..."
echo ""

# Generate a secure auth key
AUTH_KEY=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p -c 32)

echo -e "${CYAN}🔐 Generated AUTH_KEY: ${AUTH_KEY:0:16}...${NC}"
echo ""

echo -e "${YELLOW}📝 Next Steps:${NC}"
echo ""
echo -e "${BLUE}1. Create Cloudflare AI Gateway:${NC}"
echo "   - Login to Cloudflare Dashboard"
echo "   - Navigate to AI → AI Gateway"
echo "   - Create gateway named 'one-balance'"
echo ""

echo -e "${BLUE}2. Clone and deploy one-balance:${NC}"
echo "   cd .."
echo "   git clone https://github.com/glidea/one-balance.git"
echo "   cd one-balance"
echo "   pnpm install"
echo "   AUTH_KEY=\"$AUTH_KEY\" pnpm run deploycf"
echo ""

echo -e "${BLUE}3. Configure API keys in web interface:${NC}"
echo "   - Access your worker URL"
echo "   - Add API keys through web UI:"
echo "     * AnyRouter: $ANYROUTER_API_KEY"
echo "     * Gemini: $GEMINI_API_KEY"
echo "     * Qwen: $QWEN_API_KEY"
echo ""

echo -e "${BLUE}4. Update Claude Code settings:${NC}"
echo '   {
     "env": {
       "ANTHROPIC_BASE_URL": "https://<worker-url>/api/compat",
       "ANTHROPIC_API_KEY": "'$AUTH_KEY'",
       "ANTHROPIC_MODEL": "google-ai-studio/gemini-2.5-pro"
     }
   }'
echo ""

# Save auth key for later use
echo "AUTH_KEY=$AUTH_KEY" >> .env.local
echo -e "${GREEN}✅ AUTH_KEY saved to .env.local${NC}"

echo -e "${CYAN}🎯 Benefits of One-Balance:${NC}"
echo "✅ Lower API key ban risk"
echo "✅ Smart error handling with cooling periods"
echo "✅ Auto circuit breaker for banned keys"
echo "✅ Web UI for key management"
echo "✅ Production-ready with observability"
echo ""

echo -e "${GREEN}🚀 Ready to deploy one-balance!${NC}"