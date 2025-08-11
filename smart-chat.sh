#!/bin/bash

# Smart Chat - Context-aware AI like Claude Code but with free tokens

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Load API keys
if [ -f .env.local ]; then
    source .env.local
fi

echo -e "${CYAN}🧠 Smart Chat - Context-Aware AI Assistant${NC}"
echo -e "${GREEN}💡 Like Claude Code but with free tokens${NC}"
echo -e "${BLUE}🔍 Can see your project files, git status, and more${NC}"
echo ""

# Function to get project context
get_project_context() {
    local context=""
    
    # Current directory
    context+="Current directory: $(pwd)\n"
    
    # Git status if available
    if git rev-parse --git-dir > /dev/null 2>&1; then
        context+="Git status:\n$(git status --porcelain)\n"
        context+="Current branch: $(git branch --show-current)\n"
        context+="Recent commits:\n$(git log --oneline -3)\n"
    fi
    
    # List current directory files
    context+="Files in current directory:\n$(ls -la | head -10)\n"
    
    # Package.json if exists
    if [ -f "package.json" ]; then
        context+="Package.json exists - Node.js project\n"
    fi
    
    # README if exists
    if [ -f "README.md" ]; then
        context+="README.md content (first 10 lines):\n$(head -10 README.md)\n"
    fi
    
    echo "$context"
}

# Function to chat with context
chat_with_context() {
    local user_prompt="$1"
    local context=$(get_project_context)
    
    # Combine context with user prompt
    local full_prompt="PROJECT CONTEXT:
$context

USER REQUEST: $user_prompt

Please help with this request considering the project context above. Be specific and practical like Claude Code would be."

    echo -e "${BLUE}🤖 Analyzing project context and responding...${NC}"
    
    # Try Gemini first
    if [ ! -z "$GEMINI_API_KEY" ]; then
        local response=$(curl -s -w "\n%{http_code}" -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$GEMINI_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"contents\": [{\"role\": \"user\", \"parts\": [{\"text\": \"$(echo "$full_prompt" | sed 's/"/\\"/g' | tr '\n' ' ')\"}]}]}")
        
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
                echo -e "${GREEN}🤖 Smart Assistant:${NC}"
                echo "$text"
                echo ""
                return 0
            fi
        fi
    fi
    
    echo -e "${RED}❌ Failed to get response${NC}"
    return 1
}

# Function to execute commands suggested by AI
execute_command() {
    local command="$1"
    echo -e "${YELLOW}🔧 Executing: $command${NC}"
    echo -e "${BLUE}Press Enter to execute, or Ctrl+C to cancel${NC}"
    read
    eval "$command"
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
        "context"|"ctx")
            echo -e "${PURPLE}📋 Current Project Context:${NC}"
            get_project_context
            continue
            ;;
        "help"|"h")
            echo -e "${CYAN}💡 Smart Chat Commands:${NC}"
            echo "  context/ctx  - Show project context"
            echo "  help/h       - Show this help"
            echo "  quit/q       - Exit"
            echo "  Any other text - Chat with context awareness"
            echo ""
            continue
            ;;
        "")
            continue
            ;;
        *)
            chat_with_context "$user_input"
            ;;
    esac
done