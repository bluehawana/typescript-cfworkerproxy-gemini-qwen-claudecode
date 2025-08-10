#!/bin/bash

# CoolClaude - Direct free token Claude interface
# Simple version compatible with macOS bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
WORKER_URL="https://claude-worker-proxy.bluehawana.workers.dev"

# Load API keys from .env.local file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$HOME/Projects/onebalance/claude-worker-proxy/.env.local"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    # Fallback values
    ANYROUTER_API_KEY="sk-0tLHsbD4IpO7bMfzuZSDh0V6JVQ8Ng39TBFIMywpStkXMjQ3"
    GEMINI_API_KEY="YOUR_NEW_GEMINI_KEY_HERE"
    QWEN_API_KEY="sk-adfaf77b469b4975babd846aae3bf896"
fi

show_usage() {
    echo -e "${CYAN}🆒 CoolClaude - Free Token Claude Interface${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  coolclaude \"your prompt here\"                    # Use AnyRouter (default)"
    echo "  coolclaude -p gemini \"your prompt here\"         # Use Gemini"
    echo "  coolclaude -p qwen \"your prompt here\"           # Use Qwen"
    echo "  coolclaude -s                                     # Show status"
    echo "  coolclaude -t                                     # Test all providers"
    echo ""
    echo -e "${GREEN}💰 Cost: FREE tokens! No paid Claude API needed!${NC}"
}

show_status() {
    echo -e "${CYAN}🆒 CoolClaude Provider Status:${NC}"
    echo ""
    
    if [ "$ANYROUTER_API_KEY" != "YOUR_ANYROUTER_API_KEY_HERE" ]; then
        echo -e "${GREEN}✅ AnyRouter${NC} - claude-3-5-sonnet-20241022 - ${GREEN}CONFIGURED${NC}"
    else
        echo -e "${RED}❌ AnyRouter${NC} - NOT CONFIGURED"
    fi
    
    if [ "$GEMINI_API_KEY" != "YOUR_NEW_GEMINI_KEY_HERE" ]; then
        echo -e "${GREEN}✅ Gemini${NC} - gemini-2.5-flash - ${GREEN}CONFIGURED${NC}"
    else
        echo -e "${RED}❌ Gemini${NC} - NOT CONFIGURED (revoked key)"
    fi
    
    if [ "$QWEN_API_KEY" != "YOUR_QWEN_API_KEY_HERE" ]; then
        echo -e "${GREEN}✅ Qwen${NC} - qwen-max - ${GREEN}CONFIGURED${NC}"
    else
        echo -e "${RED}❌ Qwen${NC} - NOT CONFIGURED"
    fi
}

call_claude() {
    local provider=$1
    local prompt=$2
    local api_key=""
    local model=""
    local endpoint=""
    
    case $provider in
        "anyrouter")
            api_key="$ANYROUTER_API_KEY"
            model="claude-3-5-sonnet-20241022"
            endpoint="anyrouter/anyrouter.top"
            ;;
        "gemini")
            api_key="$GEMINI_API_KEY"
            model="gemini-2.5-flash"
            endpoint="gemini/https://generativelanguage.googleapis.com/v1beta"
            ;;
        "qwen")
            api_key="$QWEN_API_KEY"
            model="qwen-max"
            endpoint="qwen/https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"
            ;;
    esac
    
    if [ -z "$api_key" ] || [[ "$api_key" == *"YOUR_"* ]]; then
        echo -e "${RED}❌ $provider API key not configured!${NC}"
        return 1
    fi
    
    echo -e "${PURPLE}🆒 Using $provider ($model) - FREE tokens!${NC}"
    echo -e "${BLUE}🤖 Thinking...${NC}"
    echo ""
    
    local max_tokens=1000
    if [ "$provider" = "qwen" ]; then
        max_tokens=2000
    fi
    
    local response=$(curl -s -X POST "${WORKER_URL}/${endpoint}/v1/messages" \
        -H "x-api-key: ${api_key}" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"${model}\",\"max_tokens\":${max_tokens},\"messages\":[{\"role\":\"user\",\"content\":\"${prompt}\"}]}")
    
    # Simple response parsing
    if [[ "$response" == *"\"text\":"* ]]; then
        local text=$(echo "$response" | sed -n 's/.*"text":"\([^"]*\)".*/\1/p' | head -1)
        echo -e "${GREEN}💬 Response:${NC}"
        echo "$text"
        echo ""
        echo -e "${GREEN}✅ Success! Used FREE $provider tokens${NC}"
    else
        echo -e "${RED}❌ Error response:${NC}"
        echo "$response" | head -3
        echo ""
        echo -e "${YELLOW}💡 Try a different provider${NC}"
    fi
}

# Main logic
case "$1" in
    -h|--help)
        show_usage
        ;;
    -s|--status)
        show_status
        ;;
    -t|--test)
        echo -e "${CYAN}🧪 Testing CoolClaude providers...${NC}"
        echo ""
        call_claude "anyrouter" "Say hello and identify yourself briefly"
        echo "---"
        call_claude "qwen" "Say hello and identify yourself briefly"
        ;;
    -p)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}❌ Provider and prompt required${NC}"
            show_usage
            exit 1
        fi
        call_claude "$2" "$3"
        ;;
    "")
        show_usage
        ;;
    *)
        call_claude "anyrouter" "$1"
        ;;
esac