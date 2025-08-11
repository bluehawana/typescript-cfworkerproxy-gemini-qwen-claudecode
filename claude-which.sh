#!/bin/bash

# Claude Which - Show current Claude Code configuration

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔍 Current Claude Code Configuration:${NC}"
echo ""

# Check settings file
if [ -f ~/.claude/settings.json ]; then
    echo -e "${YELLOW}📁 Settings file: ~/.claude/settings.json${NC}"
    
    # Extract key values
    BASE_URL=$(cat ~/.claude/settings.json | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('env', {}).get('ANTHROPIC_BASE_URL', 'Not set'))
except:
    print('Error reading settings')
")
    
    API_KEY=$(cat ~/.claude/settings.json | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    key = data.get('env', {}).get('ANTHROPIC_API_KEY', 'Not set')
    if key != 'Not set' and len(key) > 10:
        print(key[:10] + '...')
    else:
        print(key)
except:
    print('Error reading settings')
")
    
    MODEL=$(cat ~/.claude/settings.json | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('env', {}).get('ANTHROPIC_MODEL', 'Not set'))
except:
    print('Error reading settings')
")
    
    echo -e "${GREEN}🌐 Base URL:${NC} $BASE_URL"
    echo -e "${GREEN}🔑 API Key:${NC} $API_KEY"
    echo -e "${GREEN}🤖 Model:${NC} $MODEL"
    echo ""
    
    # Determine provider
    if [[ "$BASE_URL" == *"anyrouter"* ]]; then
        echo -e "${GREEN}✅ Provider: AnyRouter (Direct)${NC}"
        echo -e "${BLUE}💰 Cost: FREE/Cheap${NC}"
    elif [[ "$BASE_URL" == *"claude-worker-proxy"* ]]; then
        echo -e "${YELLOW}⚠️  Provider: Worker Proxy${NC}"
        echo -e "${BLUE}💡 Consider switching to direct AnyRouter${NC}"
    elif [[ "$BASE_URL" == *"anthropic"* ]] || [ "$BASE_URL" = "Not set" ]; then
        echo -e "${YELLOW}💸 Provider: Official Anthropic (PAID)${NC}"
        echo -e "${BLUE}💡 Consider switching to AnyRouter for free tokens${NC}"
    else
        echo -e "${CYAN}🔍 Provider: Custom ($BASE_URL)${NC}"
    fi
    
else
    echo -e "${YELLOW}⚠️  No Claude Code settings file found${NC}"
    echo -e "${BLUE}💡 Run 'claude config' to set up${NC}"
fi

echo ""
echo -e "${CYAN}💡 Quick provider switching:${NC}"
echo "   ./claude-use-anyrouter.sh  # Direct AnyRouter (recommended)"
echo "   ./claude-use-gemini.sh     # Gemini via worker proxy"
echo "   ./claude-use-qwen.sh       # Qwen via worker proxy"