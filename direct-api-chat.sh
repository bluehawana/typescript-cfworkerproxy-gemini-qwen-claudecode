#!/bin/bash

# Direct API Chat - Bypass all proxies, use APIs directly

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

echo -e "${CYAN}🚀 Direct API Chat (No Proxies)${NC}"
echo -e "${GREEN}💡 Direct calls to provider APIs${NC}"
echo -e "${BLUE}💬 Type 'quit' to exit, 'status' to check providers${NC}"
echo ""

# Function to check provider status
check_providers() {
    echo -e "${CYAN}🔍 Checking provider status...${NC}"
    
    # Test Gemini directly
    if [ ! -z "$GEMINI_API_KEY" ]; then
        echo -e "${YELLOW}Testing Gemini (direct)...${NC}"
        local gemini_test=$(curl -s -w "%{http_code}" -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$GEMINI_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"contents": [{"role": "user", "parts": [{"text": "ping"}]}]}' \
            -o /dev/null)
        
        if [ "$gemini_test" = "200" ]; then
            echo -e "${GREEN}✅ Gemini (direct): Available${NC}"
        else
            echo -e "${RED}❌ Gemini (direct): Unavailable (HTTP $gemini_test)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Gemini: No API key${NC}"
    fi
    
    # Test Qwen directly
    if [ ! -z "$QWEN_API_KEY" ]; then
        echo -e "${YELLOW}Testing Qwen (direct)...${NC}"
        local qwen_test=$(curl -s -w "%{http_code}" -X POST "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation" \
            -H "Authorization: Bearer $QWEN_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"model":"qwen-max","input":{"messages":[{"role":"user","content":"ping"}]}}' \
            -o /dev/null)
        
        if [ "$qwen_test" = "200" ]; then
            echo -e "${GREEN}✅ Qwen (direct): Available${NC}"
        else
            echo -e "${RED}❌ Qwen (direct): Unavailable (HTTP $qwen_test)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Qwen: No API key${NC}"
    fi
    echo ""
}

# Function to chat with direct APIs
chat_direct() {
    local prompt="$1"
    
    # Try Gemini directly first
    if [ ! -z "$GEMINI_API_KEY" ]; then
        echo -e "${BLUE}🔄 Trying Gemini (direct)...${NC}"
        local response=$(curl -s -w "\n%{http_code}" -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$GEMINI_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"contents\": [{\"role\": \"user\", \"parts\": [{\"text\": \"$prompt\"}]}]}")
        
        local http_code=$(echo "$response" | tail -1)
        local body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            local text=$(echo "$body" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    if 'candidates' in data and len(data['candidates']) > 0:
        candidate = data['candidates'][0]
        if 'content' in candidate and 'parts' in candidate['content']:
            text = ''.join([part.get('text', '') for part in candidate['content']['parts']])
            print(text)
            sys.exit(0)
    sys.exit(1)
except Exception as e:
    sys.exit(1)
" 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}🤖 Gemini:${NC}"
                echo "$text"
                echo ""
                return 0
            fi
        fi
        echo -e "${YELLOW}⚠️  Gemini failed (HTTP $http_code), trying Qwen...${NC}"
    fi
    
    # Try Qwen directly
    if [ ! -z "$QWEN_API_KEY" ]; then
        echo -e "${BLUE}🔄 Trying Qwen (direct)...${NC}"
        local response=$(curl -s -w "\n%{http_code}" -X POST "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation" \
            -H "Authorization: Bearer $QWEN_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"model\":\"qwen-max\",\"input\":{\"messages\":[{\"role\":\"user\",\"content\":\"$prompt\"}]}}")
        
        local http_code=$(echo "$response" | tail -1)
        local body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            local text=$(echo "$body" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    if 'output' in data and 'text' in data['output']:
        print(data['output']['text'])
        sys.exit(0)
    sys.exit(1)
except Exception as e:
    sys.exit(1)
" 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}🤖 Qwen:${NC}"
                echo "$text"
                echo ""
                return 0
            fi
        fi
        echo -e "${YELLOW}⚠️  Qwen failed (HTTP $http_code)${NC}"
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
            chat_direct "$user_input"
            ;;
    esac
done