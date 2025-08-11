#!/bin/bash

# Claude Manager - Switch between different Claude environments
# Manages: Official Claude Pro, Free APIs, One-Balance, etc.

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.claude-backups"

# Load API keys
if [ -f "$SCRIPT_DIR/.env.local" ]; then
    source "$SCRIPT_DIR/.env.local"
fi

show_usage() {
    echo -e "${CYAN}🎛️  Claude Manager - Multi-Environment Switcher${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./claude-manager.sh [command]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  status          - Show current Claude configuration"
    echo "  official        - Switch to official Claude Pro (paid)"
    echo "  free            - Switch to free APIs (Gemini/Qwen direct)"
    echo "  one-balance     - Switch to one-balance system"
    echo "  backup          - Backup current Claude settings"
    echo "  restore         - Restore Claude settings from backup"
    echo "  list-backups    - List available backups"
    echo "  chat            - Start interactive chat with current setup"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./claude-manager.sh status"
    echo "  ./claude-manager.sh official"
    echo "  ./claude-manager.sh free"
    echo "  ./claude-manager.sh chat"
    echo ""
    echo -e "${GREEN}💡 This prevents conflicts between different Claude setups${NC}"
}

show_status() {
    echo -e "${CYAN}📊 Current Claude Configuration Status${NC}"
    echo ""
    
    # Check if Claude settings exist
    if [ -f ~/.claude/settings.json ]; then
        echo -e "${GREEN}📁 Claude settings found: ~/.claude/settings.json${NC}"
        
        # Extract key info
        local base_url=$(cat ~/.claude/settings.json | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('env', {}).get('ANTHROPIC_BASE_URL', 'Not set'))
except:
    print('Error reading settings')
" 2>/dev/null)
        
        local api_key=$(cat ~/.claude/settings.json | python3 -c "
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
" 2>/dev/null)
        
        echo -e "${BLUE}🌐 Base URL:${NC} $base_url"
        echo -e "${BLUE}🔑 API Key:${NC} $api_key"
        
        # Determine environment type
        if [[ "$base_url" == *"anthropic.com"* ]] || [ "$base_url" = "Not set" ]; then
            echo -e "${PURPLE}🏢 Environment: Official Claude Pro${NC}"
        elif [[ "$base_url" == *"one-balance"* ]]; then
            echo -e "${GREEN}⚖️  Environment: One-Balance System${NC}"
        elif [[ "$base_url" == *"claude-worker-proxy"* ]]; then
            echo -e "${YELLOW}🔧 Environment: Custom Worker Proxy${NC}"
        else
            echo -e "${CYAN}❓ Environment: Custom ($base_url)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No Claude settings found${NC}"
        echo -e "${BLUE}💡 Claude will use default official API${NC}"
    fi
    
    echo ""
    
    # Check environment variables
    if [ ! -z "$ANTHROPIC_API_KEY" ]; then
        echo -e "${GREEN}🌍 Environment variable ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:0:10}...${NC}"
    fi
    
    if [ ! -z "$ANTHROPIC_BASE_URL" ]; then
        echo -e "${GREEN}🌍 Environment variable ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL${NC}"
    fi
    
    # Check available backups
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo ""
        echo -e "${CYAN}💾 Available backups:${NC}"
        ls -la "$BACKUP_DIR" | grep -E "\.json$" | awk '{print "  " $9 " (" $6 " " $7 " " $8 ")"}'
    fi
}

backup_settings() {
    mkdir -p "$BACKUP_DIR"
    
    if [ -f ~/.claude/settings.json ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_file="$BACKUP_DIR/settings_${timestamp}.json"
        cp ~/.claude/settings.json "$backup_file"
        echo -e "${GREEN}✅ Settings backed up to: $backup_file${NC}"
    else
        echo -e "${YELLOW}⚠️  No settings file to backup${NC}"
    fi
}

switch_to_official() {
    echo -e "${PURPLE}🏢 Switching to Official Claude Pro...${NC}"
    
    # Backup current settings
    backup_settings
    
    # Remove custom settings to use official API
    rm -rf ~/.claude/settings.json 2>/dev/null
    
    # Clear environment variables
    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_BASE_URL
    
    echo -e "${GREEN}✅ Switched to Official Claude Pro${NC}"
    echo -e "${BLUE}💡 Claude will now use your official subscription${NC}"
    echo -e "${YELLOW}💰 Note: This uses your paid Claude Pro credits${NC}"
}

switch_to_free() {
    echo -e "${GREEN}🆓 Switching to Free APIs (Direct)...${NC}"
    
    # Backup current settings
    backup_settings
    
    # Remove Claude settings to avoid conflicts
    rm -rf ~/.claude/settings.json 2>/dev/null
    
    # Clear environment variables
    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_BASE_URL
    
    echo -e "${GREEN}✅ Switched to Free API mode${NC}"
    echo -e "${BLUE}💡 Use './direct-api-chat.sh' for free Gemini/Qwen access${NC}"
    echo -e "${GREEN}💰 Note: This uses free API tokens${NC}"
}

switch_to_one_balance() {
    echo -e "${GREEN}⚖️  Switching to One-Balance System...${NC}"
    
    # Backup current settings
    backup_settings
    
    # Create one-balance settings
    mkdir -p ~/.claude
    cat > ~/.claude/settings.json << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://one-balance.bluehawana.workers.dev/api/compat",
    "ANTHROPIC_API_KEY": "8cc200d2003f89e958c64a9d918c9d7924e5941d098ca68b375645232d7e8b7b",
    "ANTHROPIC_MODEL": "google-ai-studio/gemini-2.5-pro",
    "API_TIMEOUT_MS": "600000"
  }
}
EOF
    
    echo -e "${GREEN}✅ Switched to One-Balance System${NC}"
    echo -e "${BLUE}💡 Make sure to add API keys via web UI: https://one-balance.bluehawana.workers.dev${NC}"
    echo -e "${GREEN}💰 Note: This uses free tokens with production-grade reliability${NC}"
}

start_chat() {
    echo -e "${CYAN}💬 Starting chat with current configuration...${NC}"
    show_status
    echo ""
    
    # Check current environment and start appropriate chat
    if [ -f ~/.claude/settings.json ]; then
        local base_url=$(cat ~/.claude/settings.json | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('env', {}).get('ANTHROPIC_BASE_URL', ''))
except:
    print('')
" 2>/dev/null)
        
        if [[ "$base_url" == *"one-balance"* ]]; then
            echo -e "${GREEN}🚀 Starting Claude with One-Balance...${NC}"
            claude
        else
            echo -e "${GREEN}🚀 Starting Claude with custom settings...${NC}"
            claude
        fi
    else
        echo -e "${PURPLE}🚀 Starting Claude with Official API...${NC}"
        claude
    fi
}

list_backups() {
    echo -e "${CYAN}💾 Available Claude Settings Backups${NC}"
    echo ""
    
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        ls -la "$BACKUP_DIR" | grep -E "\.json$" | while read -r line; do
            local file=$(echo "$line" | awk '{print $9}')
            local date=$(echo "$line" | awk '{print $6 " " $7 " " $8}')
            echo -e "${GREEN}📄 $file${NC} (${BLUE}$date${NC})"
        done
    else
        echo -e "${YELLOW}⚠️  No backups found${NC}"
    fi
}

restore_settings() {
    echo -e "${CYAN}🔄 Restore Claude Settings${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ] || [ ! "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo -e "${YELLOW}⚠️  No backups available${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Available backups:${NC}"
    local files=($(ls "$BACKUP_DIR"/*.json 2>/dev/null))
    
    for i in "${!files[@]}"; do
        local file=$(basename "${files[$i]}")
        echo -e "${GREEN}$((i+1)). $file${NC}"
    done
    
    echo ""
    echo -n "Select backup to restore (1-${#files[@]}): "
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#files[@]}" ]; then
        local selected_file="${files[$((choice-1))]}"
        mkdir -p ~/.claude
        cp "$selected_file" ~/.claude/settings.json
        echo -e "${GREEN}✅ Settings restored from: $(basename "$selected_file")${NC}"
    else
        echo -e "${RED}❌ Invalid selection${NC}"
    fi
}

# Main command handling
case "$1" in
    "status")
        show_status
        ;;
    "official")
        switch_to_official
        ;;
    "free")
        switch_to_free
        ;;
    "one-balance")
        switch_to_one_balance
        ;;
    "backup")
        backup_settings
        ;;
    "restore")
        restore_settings
        ;;
    "list-backups")
        list_backups
        ;;
    "chat")
        start_chat
        ;;
    "")
        show_usage
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac