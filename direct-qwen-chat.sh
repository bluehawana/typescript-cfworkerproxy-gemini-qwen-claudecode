#!/bin/bash

# Direct Qwen Chat - Bypass Claude CLI entirely

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Load API key
if [ -f .env.local ]; then
    source .env.local
fi

if [ -z "$QWEN_API_KEY" ]; then
    echo -e "${RED}❌ QWEN_API_KEY not found in .env.local${NC}"
    exit 1
fi

WORKER_URL="https://claude-worker-proxy.bluehawana.workers.dev/qwen/dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation/v1/messages"

echo -e "${CYAN}🚀 Direct Qwen Chat (No Claude CLI needed!)${NC}"
echo -e "${GREEN}🔑 Using Qwen free tokens${NC}"
echo -e "${BLUE}💬 Type 'quit' or 'exit' to end chat${NC}"
echo ""

# Function to make API call
chat_with_qwen() {
    local prompt="$1"
    
    echo -e "${BLUE}🤖 Qwen is thinking...${NC}"
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "$WORKER_URL" \
        -H "x-api-key: $QWEN_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"claude-3-5-sonnet\",\"max_tokens\":2000,\"messages\":[{\"role\":\"user\",\"content\":\"$prompt\"}]}")
    
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        # Parse JSON response
        local text=$(echo "$body" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'content' in data and len(data['content']) > 0:
        print(data['content'][0]['text'])
    else:
        print('No response content found')
except Exception as e:
    print('Error parsing response:', str(e))
    print('Raw response:', sys.stdin.read())
" 2>/dev/null)
        
        echo -e "${GREEN}🤖 Qwen:${NC}"
        echo "$text"
    else
        echo -e "${RED}❌ Error (HTTP $http_code):${NC}"
        echo "$body"
    fi
    echo ""
}

# Interactive chat loop
while true; do
    echo -e -n "${CYAN}You: ${NC}"
    read -r user_input
    
    # Check for exit commands
    if [[ "$user_input" == "quit" || "$user_input" == "exit" || "$user_input" == "q" ]]; then
        echo -e "${YELLOW}👋 Goodbye!${NC}"
        break
    fi
    
    # Skip empty input
    if [ -z "$user_input" ]; then
        continue
    fi
    
    # Make API call
    chat_with_qwen "$user_input"
done