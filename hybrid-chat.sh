#!/bin/bash

# Hybrid Chat - Best of both worlds
# Uses one-balance for Gemini, custom worker for AnyRouter/Qwen

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

# Configuration
ONE_BALANCE_URL="https://one-balance.bluehawana.workers.dev"
ONE_BALANCE_AUTH="8cc200d2003f89e958c64a9d918c9d7924e5941d098ca68b375645232d7e8b7b"
CUSTOM_WORKER_URL="https://claude-worker-proxy.bluehawana.workers.dev"

echo -e "${CYAN}🎯 Hybrid AI Chat System${NC}"
echo -e "${GREEN}💡 Gemini via one-balance (production-grade)${NC}"
echo -e "${GREEN}💡 AnyRouter/Qwen via custom worker${NC}"
echo -e "${BLUE}💬 Type 'quit' to exit, 'status' to check providers${NC}"
echo ""

# Function to check provider status
check_providers() {
    echo -e "${CYAN}🔍 Checking provider status...${NC}"
    
    # Test Gemini via one-balance
    echo -e "${YELLOW}Testing Gemini (one-balance)...${NC}"
    local gemini_test=$(curl -s -w "%{http_code}" -X POST "$ONE_BALANCE_URL/api/google-ai-studio/v1/models/gemini-2.5-flash:generateContent" \
        -H "x-goog-api-key: $ONE_BALANCE_AUTH" \
        -H "Content-Type: application/json" \
        -d '{"contents": [{"role": "user", "parts": [{"text": "ping"}]}]}' \
        -o /dev/null)
    
    if [ "$gemini_test" = "200" ]; then
        echo -e "${GREEN}✅ Gemini (one-balance): Available${NC}"
    else
        echo -e "${RED}❌ Gemini (one-balance): Unavailable (HTTP $gemini_test)${NC}"
    fi
    
    # Test AnyRouter via custom worker
    if [ ! -z "$ANYROUTER_API_KEY" ]; then
        echo -e "${YELLOW}Testing AnyRouter (custom worker)...${NC}"
        local anyrouter_test=$(curl -s -w "%{http_code}" -X POST "$CUSTOM_WORKER_URL/anyrouter/anyrouter.top/v1/messages" \
            -H "x-api-key: $ANYROUTER_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"model":"claude-3-5-sonnet-20241022","messages":[{"role":"user","content":"ping"}]}' \
            -o /dev/null)
        
        if [ "$anyrouter_test" = "200" ]; then
            echo -e "${GREEN}✅ AnyRouter: Available${NC}"
        else
            echo -e "${RED}❌ AnyRouter: Blocked/Unavailable (HTTP $anyrouter_test)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  AnyRouter: No API key${NC}"
    fi
    
    # Test Qwen via custom worker
    if [ ! -z "$QWEN_API_KEY" ]; then
        echo -e "${YELLOW}Testing Qwen (custom worker)...${NC}"
        local qwen_test=$(curl -s -w "%{http_code}" -X POST "$CUSTOM_WORKER_URL/qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation/v1/messages" \
            -H "x-api-key: $QWEN_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"model":"claude-3-5-sonnet","messages":[{"role":"user","content":"ping"}]}' \
            -o /dev/null)
        
        if [ "$qwen_test" = "200" ]; then
            echo -e "${GREEN}✅ Qwen: Available${NC}"
        else
            echo -e "${RED}❌ Qwen: Unavailable (HTTP $qwen_test)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Qwen: No API key${NC}"
    fi
    echo ""
}

# Function to chat with best available provider
chat_hybrid() {
    local prompt="$1"
    
    # Try Gemini via one-balance first (most reliable)
    echo -e "${BLUE}🔄 Trying Gemini (one-balance)...${NC}"
    local response=$(curl -s -w "\n%{http_code}" -X POST "$ONE_BALANCE_URL/api/compat/chat/completions" \
        -H "Authorization: Bearer $ONE_BALANCE_AUTH" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"google-ai-studio/gemini-2.5-flash\",\"messages\":[{\"role\":\"user\",\"content\":\"$prompt\"}]}")
    
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        local text=$(echo "$body" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    if 'choices' in data and len(data['choices']) > 0:
        print(data['choices'][0]['message']['content'])
        sys.exit(0)
    else:
        sys.exit(1)
except:
    sys.exit(1)
" 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}🤖 Gemini (one-balance):${NC}"
            echo "$text"
            echo ""
            return 0
        fi
    fi
    
    # Fallback to Qwen via custom worker
    if [ ! -z "$QWEN_API_KEY" ]; then
        echo -e "${YELLOW}⚠️  Gemini failed, trying Qwen...${NC}"
        local response=$(curl -s -w "\n%{http_code}" -X POST "$CUSTOM_WORKER_URL/qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation/v1/messages" \
            -H "x-api-key: $QWEN_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"model\":\"claude-3-5-sonnet\",\"max_tokens\":2000,\"messages\":[{\"role\":\"user\",\"content\":\"$prompt\"}]}")
        
        local http_code=$(echo "$response" | tail -1)
        local body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            local text=$(echo "$body" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    if 'content' in data and len(data['content']) > 0:
        print(data['content'][0]['text'])
        sys.exit(0)
    else:
        sys.exit(1)
except:
    sys.exit(1)
" 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}🤖 Qwen:${NC}"
                echo "$text"
                echo ""
                return 0
            fi
        fi
    fi
    
    echo -e "${RED}❌ All providers failed${NC}"
    echo ""
    return 1
}

# Interactive chat loop
while true; do
    echo -e -n "${CYAN}You: ${NC}"
    read -r user_input
    
    case "$user_input" in
        "quit"|"exit"|"q")
            echo -e "${YELLOW}👋 Goodbye!${NC}"
            break
            ;;
        "status"|"check")
            check_providers
            continue
            ;;
        "")
            continue
            ;;
        *)
            chat_hybrid "$user_input"
            ;;
    esac
done