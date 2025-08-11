#!/bin/bash

# Balance Chat - Inspired by one-balance project
# Intelligent provider switching with fallback

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

WORKER_URL="https://claude-worker-proxy.bluehawana.workers.dev"

echo -e "${CYAN}🎯 Smart Balance Chat (Auto Provider Selection)${NC}"
echo -e "${GREEN}💡 Automatically tries: AnyRouter → Gemini → Qwen → Cerebras${NC}"
echo -e "${BLUE}💬 Type 'quit' to exit, 'status' to check providers${NC}"
echo ""

# Function to check provider status
check_providers() {
    echo -e "${CYAN}🔍 Checking provider status...${NC}"
    
    # Test AnyRouter
    if [ ! -z "$ANYROUTER_API_KEY" ]; then
        local test=$(curl -s -w "%{http_code}" -X POST "$WORKER_URL/anyrouter/anyrouter.top/v1/messages" \
            -H "x-api-key: $ANYROUTER_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"model":"claude-3-5-sonnet-20241022","messages":[{"role":"user","content":"Hello"}]}' \
            -o /dev/null)
        if [ "$test" = "200" ]; then
            echo -e "${GREEN}✅ AnyRouter: Available${NC}"
        else
            echo -e "${RED}❌ AnyRouter: Unavailable (HTTP $test)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  AnyRouter: No API key${NC}"
    fi
    
    # Test Gemini
    if [ ! -z "$GEMINI_API_KEY" ]; then
        local test=$(curl -s -w "%{http_code}" -X POST "$WORKER_URL/gemini/generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent/v1/messages" \
            -H "x-api-key: $GEMINI_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"model":"claude-3-5-sonnet","messages":[{"role":"user","content":"Hello"}]}' \
            -o /dev/null)
        if [ "$test" = "200" ]; then
            echo -e "${GREEN}✅ Gemini: Available${NC}"
        else
            echo -e "${RED}❌ Gemini: Unavailable (HTTP $test)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Gemini: No API key${NC}"
    fi
    
    # Test Qwen
    if [ ! -z "$QWEN_API_KEY" ]; then
        local test=$(curl -s -w "%{http_code}" -X POST "$WORKER_URL/qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation/v1/messages" \
            -H "x-api-key: $QWEN_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"model":"claude-3-5-sonnet","messages":[{"role":"user","content":"Hello"}]}' \
            -o /dev/null)
        if [ "$test" = "200" ]; then
            echo -e "${GREEN}✅ Qwen: Available${NC}"
        else
            echo -e "${RED}❌ Qwen: Unavailable (HTTP $test)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Qwen: No API key${NC}"
    fi
    
    # Test Cerebras
    if [ ! -z "$CEREBRAS_API_KEY" ]; then
        local test=$(curl -s -w "%{http_code}" -X POST "$WORKER_URL/cerebras/api.cerebras.ai/v1/chat/completions/v1/messages" \
            -H "x-api-key: $CEREBRAS_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"model":"claude-3-5-sonnet","messages":[{"role":"user","content":"Hello"}]}' \
            -o /dev/null)
        if [ "$test" = "200" ]; then
            echo -e "${GREEN}✅ Cerebras: Available${NC}"
        else
            echo -e "${RED}❌ Cerebras: Unavailable (HTTP $test)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Cerebras: No API key${NC}"
    fi
    echo ""
}

# Function to try providers in order
chat_with_balance() {
    local prompt="$1"
    local providers=("anyrouter" "gemini" "qwen" "cerebras")
    local endpoints=(
        "anyrouter/anyrouter.top/v1/messages"
        "gemini/generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent/v1/messages"
        "qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation/v1/messages"
        "cerebras/api.cerebras.ai/v1/chat/completions/v1/messages"
    )
    local api_keys=("$ANYROUTER_API_KEY" "$GEMINI_API_KEY" "$QWEN_API_KEY" "$CEREBRAS_API_KEY")
    local models=("claude-3-5-sonnet-20241022" "claude-3-5-sonnet" "claude-3-5-sonnet" "claude-3-5-sonnet")
    
    for i in "${!providers[@]}"; do
        local provider="${providers[$i]}"
        local endpoint="${endpoints[$i]}"
        local api_key="${api_keys[$i]}"
        local model="${models[$i]}"
        
        if [ -z "$api_key" ]; then
            continue
        fi
        
        echo -e "${BLUE}🔄 Trying $provider...${NC}"
        
        local escaped_prompt=$(echo "$prompt" | sed 's/"/\\"/g')
        local response=$(curl -s -w "\n%{http_code}" -X POST "$WORKER_URL/$endpoint" \
            -H "x-api-key: $api_key" \
            -H "Content-Type: application/json" \
            -d "{\"model\":\"$model\",\"max_tokens\":2000,\"messages\":[{\"role\":\"user\",\"content\":\"$escaped_prompt\"}]}")
        
        local http_code=$(echo "$response" | tail -1)
        local body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            local text=$(echo "$body" | python3 -c "
import sys, json
content = sys.stdin.read()
try:
    data = json.loads(content)
    if 'content' in data and len(data['content']) > 0:
        print(data['content'][0]['text'])
        sys.exit(0)  # Success
    else:
        print('No response content found')
        sys.exit(1)  # Failed
except:
    # Check if it's HTML (anti-bot protection)
    if '<html>' in content.lower() or '<script>' in content.lower():
        print('Provider blocked by anti-bot protection')
        sys.exit(1)  # Failed - try next provider
    else:
        print('Error parsing JSON response')
        sys.exit(1)  # Failed
" 2>/dev/null)
            
            local parse_result=$?
            if [ $parse_result -eq 0 ]; then
                echo -e "${GREEN}🤖 $provider:${NC}"
                echo "$text"
                echo ""
                return 0
            else
                echo -e "${YELLOW}⚠️  $provider: $text, trying next...${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  $provider failed (HTTP $http_code), trying next...${NC}"
        fi
    done
    
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
            chat_with_balance "$user_input"
            ;;
    esac
done