#!/bin/bash

# Claude Provider Identification Script
# Shows which Claude provider you're currently using

SETTINGS_FILE="$HOME/.claude/settings.json"

echo "🤖 Current Claude Provider Detection:"
echo ""

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "❌ No Claude settings found - using default Claude API"
    echo "💳 Provider: Official Anthropic Claude (PAID)"
    exit 0
fi

# Check if settings file has ANTHROPIC_BASE_URL
if grep -q "ANTHROPIC_BASE_URL" "$SETTINGS_FILE"; then
    BASE_URL=$(grep "ANTHROPIC_BASE_URL" "$SETTINGS_FILE" | cut -d'"' -f4)
    
    if [[ "$BASE_URL" == *"anyrouter"* ]]; then
        echo "🆓 Provider: AnyRouter (Third-party Claude)"
        echo "💰 Cost: Cheaper than official Claude"
    elif [[ "$BASE_URL" == *"gemini"* ]]; then
        echo "🆓 Provider: Gemini (Google AI)"
        echo "💰 Cost: Free tier (1500 requests/day)"
    elif [[ "$BASE_URL" == *"qwen"* ]] || [[ "$BASE_URL" == *"dashscope"* ]]; then
        echo "🆓 Provider: Qwen (Alibaba AI)"
        echo "💰 Cost: Free tier (2000 requests/day)"
    else
        echo "🔄 Provider: Custom proxy"
        echo "🌐 URL: $BASE_URL"
    fi
    
    # Show model being used
    if grep -q "ANTHROPIC_MODEL" "$SETTINGS_FILE"; then
        MODEL=$(grep "ANTHROPIC_MODEL" "$SETTINGS_FILE" | cut -d'"' -f4)
        echo "🧠 Model: $MODEL"
    fi
    
else
    echo "💳 Provider: Official Anthropic Claude (PAID)"
    echo "💰 Cost: Premium pricing"
fi

echo ""
echo "💡 To switch providers, use: claude-provider [anyrouter|gemini|qwen|claude-pro]"
echo "🧪 To test all providers, use: test-claude-worker"