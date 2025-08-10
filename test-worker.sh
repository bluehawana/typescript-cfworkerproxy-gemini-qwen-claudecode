#!/bin/bash

# Multi-Provider Claude Worker Test Script
# Run this from anywhere to test your deployed worker

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Worker URL
WORKER_URL="https://claude-worker-proxy.bluehawana.workers.dev"

# Load environment variables if .env.local exists
if [ -f "$(dirname "$0")/.env.local" ]; then
    echo -e "${BLUE}📋 Loading API keys from .env.local...${NC}"
    source "$(dirname "$0")/.env.local"
else
    echo -e "${YELLOW}⚠️  .env.local not found. Please set API keys manually.${NC}"
fi

echo -e "${BLUE}🚀 Testing Multi-Provider Claude Worker${NC}"
echo -e "${BLUE}Worker URL: ${WORKER_URL}${NC}"
echo ""

# Test function
test_provider() {
    local provider=$1
    local endpoint=$2
    local api_key=$3
    local model=$4
    
    echo -e "${YELLOW}🧪 Testing ${provider}...${NC}"
    
    if [ -z "$api_key" ]; then
        echo -e "${RED}❌ ${provider}: API key not set${NC}"
        return 1
    fi
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "${WORKER_URL}/${endpoint}" \
        -H "x-api-key: ${api_key}" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"${model}\",\"max_tokens\":50,\"messages\":[{\"role\":\"user\",\"content\":\"Say hello in one word\"}]}")
    
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ ${provider}: Success (HTTP $http_code)${NC}"
        echo -e "${GREEN}   Response preview: $(echo "$body" | head -c 100)...${NC}"
    elif [ "$http_code" = "429" ]; then
        echo -e "${YELLOW}⏳ ${provider}: Rate limited (HTTP $http_code)${NC}"
    else
        echo -e "${RED}❌ ${provider}: Failed (HTTP $http_code)${NC}"
        echo -e "${RED}   Error: $(echo "$body" | head -c 200)${NC}"
    fi
    echo ""
}

# Test AnyRouter
if [ ! -z "$ANYROUTER_API_KEY" ]; then
    test_provider "AnyRouter" "anyrouter/anyrouter.top/v1/messages" "$ANYROUTER_API_KEY" "claude-3-5-sonnet-20241022"
else
    echo -e "${YELLOW}⚠️  AnyRouter API key not configured${NC}"
fi

# Test Gemini
if [ ! -z "$GEMINI_API_KEY" ]; then
    test_provider "Gemini" "gemini/https://generativelanguage.googleapis.com/v1beta/v1/messages" "$GEMINI_API_KEY" "gemini-2.5-flash"
else
    echo -e "${YELLOW}⚠️  Gemini API key not configured${NC}"
fi

# Test Qwen
if [ ! -z "$QWEN_API_KEY" ]; then
    test_provider "Qwen" "qwen/https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation/v1/messages" "$QWEN_API_KEY" "qwen-max"
else
    echo -e "${YELLOW}⚠️  Qwen API key not configured${NC}"
fi

# Test OpenAI (if configured)
if [ ! -z "$OPENAI_API_KEY" ]; then
    test_provider "OpenAI" "openai/api.openai.com/v1/chat/completions/v1/messages" "$OPENAI_API_KEY" "claude-3-5-sonnet"
else
    echo -e "${YELLOW}⚠️  OpenAI API key not configured (optional)${NC}"
fi

echo -e "${BLUE}🏁 Testing complete!${NC}"
echo ""
echo -e "${BLUE}💡 Usage examples:${NC}"
echo -e "${GREEN}# AnyRouter${NC}"
echo "curl -X POST \"${WORKER_URL}/anyrouter/anyrouter.top/v1/messages\" \\"
echo "  -H \"x-api-key: \$ANYROUTER_API_KEY\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"model\":\"claude-3-5-sonnet-20241022\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}'"
echo ""
echo -e "${GREEN}# Gemini${NC}"
echo "curl -X POST \"${WORKER_URL}/gemini/generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent/v1/messages\" \\"
echo "  -H \"x-api-key: \$GEMINI_API_KEY\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"model\":\"claude-3-5-sonnet\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}'"
echo ""
echo -e "${GREEN}# Qwen${NC}"
echo "curl -X POST \"${WORKER_URL}/qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation/v1/messages\" \\"
echo "  -H \"x-api-key: \$QWEN_API_KEY\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"model\":\"claude-3-5-sonnet\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}'"