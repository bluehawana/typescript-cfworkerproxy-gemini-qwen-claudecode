#!/bin/bash

# Simple AnyRouter Claude CLI setup
# Usage: ./anyrouter-claude.sh

# Load API key from .env.local
if [ -f .env.local ]; then
    source .env.local
fi

# Check if API key is available
if [ -z "$ANYROUTER_API_KEY" ]; then
    echo "❌ ANYROUTER_API_KEY not found in .env.local"
    echo "Please add your AnyRouter API key to .env.local"
    exit 1
fi

# Set environment variables for Claude CLI
export ANTHROPIC_AUTH_TOKEN="$ANYROUTER_API_KEY"
export ANTHROPIC_BASE_URL="https://anyrouter.top"

echo "🚀 Starting Claude CLI with AnyRouter..."
echo "📡 Base URL: $ANTHROPIC_BASE_URL"
echo "🔑 API Key: ${ANTHROPIC_AUTH_TOKEN:0:10}..."
echo ""

# Start Claude CLI
claude "$@"