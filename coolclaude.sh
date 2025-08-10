#!/bin/bash

# CoolClaude - Direct free token Claude interface
# Bypasses Claude Code authentication and uses your free token proxy directly

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f "$(dirname "$0")/.env.local" ]; then
    source "$(dirname "$0")/.env.local"
fi

# Default configuration
WORKER_URL="https://claude-worker-proxy.bluehawana.workers.dev"
DEFAULT_PROVIDER="anyrouter"
DEFAULT_API_KEY="$ANYROUTER_API_KEY"

# Provider configurations
declare -A PROVIDERS
PROVIDERS[anyrouter]="anyrouter/anyrouter.top"
PROVIDERS[gemini]="gemini/https://generativelanguage.googleapis.com/v1beta"
PROVIDERS[qwen]="qwen/https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"

declare -A API_KEYS
API_KEYS[anyrouter]="$ANYROUTER_API_KEY"
API_KEYS[gemini]="$GEMINI_API_KEY"
API_KEYS[qwen]="$QWEN_API_KEY"

declare -A MODELS
MODELS[anyrouter]="claude-3-5-sonnet-20241022"
MODELS[gemini]="gemini-2.5-flash"
MODELS[qwen]="qwen-max"

# Function to show usage
show_usage() {
    echo -e "${CYAN}🆒 CoolClaude - Free Token Claude Interface${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  coolclaude [options] \"your prompt here\""
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -p, --provider [anyrouter|gemini|qwen]  Choose provider (default: anyrouter)"
    echo "  -s, --status                            Show current provider status"
    echo "  -t, --test                              Test all providers"
    echo "  -h, --help                              Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  coolclaude \"Hello, how are you?\""
    echo "  coolclaude -p gemini \"What's the weather like?\""
    echo "  coolclaude -p qwen \"Translate this to Chinese\""
    echo "  coolclaude -s"
    echo ""
    echo -e "${GREEN}💰 Cost: FREE tokens! No paid Claude API needed!${NC}"
}

# Function to show provider status
show_status() {
    echo -e "${CYAN}🆒 CoolClaude Provider Status:${NC}"
    echo ""
    
    for provider in anyrouter gemini qwen; do
        local api_key="${API_KEYS[$provider]}"
        local model="${MODELS[$provider]}"
        
        if [ ! -z "$api_key" ] && [ "$api_key" != "your_${provider}_api_key_here" ]; then
            echo -e "${GREEN}✅ $provider${NC} - Model: $model - ${GREEN}CONFIGURED${NC}"
        else
            echo -e "${RED}❌ $provider${NC} - Model: $model - ${RED}NOT CONFIGURED${NC}"
        fi
    done
    
    echo ""
    echo -e "${BLUE}💡 Configure API keys in .env.local file${NC}"
}

# Function to make API call
call_claude() {
    local provider=$1
    local prompt=$2
    local api_key="${API_KEYS[$provider]}"
    local model="${MODELS[$provider]}"
    local endpoint="${PROVIDERS[$provider]}"
    
    if [ -z "$api_key" ] || [ "$api_key" = "your_${provider}_api_key_here" ]; then
        echo -e "${RED}❌ $provider API key not configured!${NC}"
        echo -e "${YELLOW}💡 Add your $provider API key to .env.local file${NC}"
        return 1
    fi
    
    echo -e "${PURPLE}🆒 Using $provider (${MODELS[$provider]}) - FREE tokens!${NC}"
    echo -e "${BLUE}🤖 Thinking...${NC}"
    echo ""
    
    # Adjust max_tokens based on provider
    local max_tokens=1000
    if [ "$provider" = "qwen" ]; then
        max_tokens=2000  # Qwen supports higher limits
    fi
    
    local response=$(curl -s -w "\n%{http_code}" -X POST "${WORKER_URL}/${endpoint}/v1/messages" \
        -H "x-api-key: ${api_key}" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"${model}\",\"max_tokens\":${max_tokens},\"messages\":[{\"role\":\"user\",\"content\":\"${prompt}\"}]}")
    
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        # Parse and display the response
        local text=$(echo "$body" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'content' in data and len(data['content']) > 0:
        print(data['content'][0]['text'])
    else:
        print('No response content found')
except:
    print('Error parsing response')
")
        echo -e "${GREEN}💬 Response:${NC}"
        echo "$text"
        echo ""
        echo -e "${GREEN}✅ Success! Used FREE $provider tokens${NC}"
    else
        echo -e "${RED}❌ Error (HTTP $http_code):${NC}"
        echo "$body"
        echo ""
        echo -e "${YELLOW}💡 Try a different provider: coolclaude -p [anyrouter|gemini|qwen]${NC}"
    fi
}

# Function to test all providers
test_all() {
    echo -e "${CYAN}🧪 Testing all CoolClaude providers...${NC}"
    echo ""
    
    for provider in anyrouter gemini qwen; do
        echo -e "${YELLOW}Testing $provider...${NC}"
        call_claude "$provider" "Say hello and identify yourself in one sentence"
        echo ""
        echo "---"
        echo ""
    done
}

# Main logic
case "$1" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -s|--status)
        show_status
        exit 0
        ;;
    -t|--test)
        test_all
        exit 0
        ;;
    -p|--provider)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}❌ Provider and prompt required${NC}"
            show_usage
            exit 1
        fi
        provider=$2
        prompt=$3
        if [[ ! " ${!PROVIDERS[@]} " =~ " ${provider} " ]]; then
            echo -e "${RED}❌ Invalid provider: $provider${NC}"
            echo -e "${YELLOW}Valid providers: ${!PROVIDERS[@]}${NC}"
            exit 1
        fi
        call_claude "$provider" "$prompt"
        ;;
    "")
        show_usage
        exit 0
        ;;
    *)
        # Default to anyrouter provider
        call_claude "$DEFAULT_PROVIDER" "$1"
        ;;
esac