#!/bin/bash

# Smart Claude - Automatically fallback to paid Claude when free tokens fail
# Usage: smart-claude "your prompt here"

SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_SETTINGS_FILE="$HOME/.claude/settings.backup.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Your paid Claude API key (set this!)
PAID_CLAUDE_API_KEY="sk-ant-YOUR_REAL_CLAUDE_API_KEY_HERE"

# Function to backup current settings
backup_settings() {
    if [ -f "$SETTINGS_FILE" ]; then
        cp "$SETTINGS_FILE" "$BACKUP_SETTINGS_FILE"
    fi
}

# Function to restore settings
restore_settings() {
    if [ -f "$BACKUP_SETTINGS_FILE" ]; then
        cp "$BACKUP_SETTINGS_FILE" "$SETTINGS_FILE"
    fi
}

# Function to switch to paid Claude
switch_to_paid_claude() {
    echo -e "${YELLOW}🔄 Free tokens failed, switching to PAID Claude Pro...${NC}"
    cat > "$SETTINGS_FILE" << JSON
{
  "env": {
    "ANTHROPIC_API_KEY": "$PAID_CLAUDE_API_KEY",
    "ANTHROPIC_MODEL": "claude-3-5-sonnet-20241022",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-3-haiku-20240307",
    "API_TIMEOUT_MS": "600000"
  }
}
JSON
}

# Function to test if current provider is working
test_current_provider() {
    echo -e "${BLUE}🧪 Testing current provider...${NC}"
    
    # Try a simple test with current settings
    local test_result=$(claude "Say 'OK'" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] && [[ "$test_result" == *"OK"* ]]; then
        echo -e "${GREEN}✅ Current provider working${NC}"
        return 0
    else
        echo -e "${RED}❌ Current provider failed: $test_result${NC}"
        return 1
    fi
}

# Function to try free providers in order
try_free_providers() {
    local providers=("anyrouter" "gemini" "qwen")
    
    for provider in "${providers[@]}"; do
        echo -e "${BLUE}🔄 Trying $provider...${NC}"
        
        # Switch to this provider
        claude-provider "$provider" > /dev/null 2>&1
        
        # Test if it works
        if test_current_provider > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $provider is working!${NC}"
            return 0
        else
            echo -e "${RED}❌ $provider failed${NC}"
        fi
    done
    
    return 1
}

# Main logic
main() {
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Usage: smart-claude \"your prompt here\"${NC}"
        echo -e "${BLUE}This script automatically tries free providers first, then falls back to paid Claude if needed.${NC}"
        exit 1
    fi
    
    # Check if paid Claude API key is set
    if [ "$PAID_CLAUDE_API_KEY" = "sk-ant-YOUR_REAL_CLAUDE_API_KEY_HERE" ]; then
        echo -e "${RED}⚠️  Please set your real Claude API key in the script first!${NC}"
        echo -e "${YELLOW}Edit the script and replace YOUR_REAL_CLAUDE_API_KEY_HERE with your actual key.${NC}"
        exit 1
    fi
    
    # Backup current settings
    backup_settings
    
    echo -e "${BLUE}🤖 Smart Claude - Trying free providers first...${NC}"
    
    # Try current provider first
    if test_current_provider; then
        echo -e "${GREEN}🎉 Using current provider${NC}"
        claude "$1"
        exit 0
    fi
    
    # Try free providers
    if try_free_providers; then
        echo -e "${GREEN}🎉 Using free provider${NC}"
        claude "$1"
        exit 0
    fi
    
    # All free providers failed, switch to paid Claude
    echo -e "${YELLOW}💳 All free providers exhausted, using PAID Claude Pro...${NC}"
    switch_to_paid_claude
    
    # Run the command with paid Claude
    claude "$1"
    
    # Restore original settings after use
    echo -e "${BLUE}🔄 Restoring original provider settings...${NC}"
    restore_settings
}

# Run main function with all arguments
main "$@"