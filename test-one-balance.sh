#!/bin/bash

# Test One-Balance System

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Load API keys
if [ -f .env.local ]; then
    source .env.local
fi

AUTH_KEY="8cc200d2003f89e958c64a9d918c9d7924e5941d098ca68b375645232d7e8b7b"
WORKER_URL="https://one-balance.bluehawana.workers.dev"

echo -e "${CYAN}🧪 Testing One-Balance System${NC}"
echo -e "${GREEN}🌐 URL: $WORKER_URL${NC}"
echo -e "${GREEN}🔐 AUTH_KEY: ${AUTH_KEY:0:20}...${NC}"
echo ""

echo -e "${YELLOW}📋 Step 1: Access Management UI${NC}"
echo "Open in browser: $WORKER_URL"
echo "Add your API keys through the web interface:"
echo "- Gemini: $GEMINI_API_KEY"
echo "- Qwen: $QWEN_API_KEY"
echo "- AnyRouter: $ANYROUTER_API_KEY"
echo ""

echo -e "${YELLOW}📋 Step 2: Test API Calls${NC}"
echo ""

echo -e "${BLUE}Testing Gemini via one-balance...${NC}"
curl -X POST "$WORKER_URL/api/google-ai-studio/v1/models/gemini-2.5-flash:generateContent" \
  -H "x-goog-api-key: $AUTH_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "role": "user",
      "parts": [{"text": "Hello from one-balance!"}]
    }]
  }' | head -5

echo ""
echo ""

echo -e "${BLUE}Testing OpenAI Compatible Format...${NC}"
curl -X POST "$WORKER_URL/api/compat/chat/completions" \
  -H "Authorization: Bearer $AUTH_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google-ai-studio/gemini-2.5-flash",
    "messages": [{"role": "user", "content": "Hello from compat API!"}]
  }' | head -5

echo ""
echo ""

echo -e "${GREEN}✅ Test complete!${NC}"
echo ""
echo -e "${CYAN}💡 Next Steps:${NC}"
echo "1. Add API keys via web UI: $WORKER_URL"
echo "2. Test API calls will work once keys are added"
echo "3. Use ./claude-one-balance.sh to start Claude with one-balance"