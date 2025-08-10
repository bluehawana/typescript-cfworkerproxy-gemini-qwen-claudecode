#!/bin/bash

# Script to set up Cloudflare Workers secrets
# Run this script to securely add your API keys to the deployed worker

echo "🔐 Setting up Cloudflare Workers secrets..."
echo "This will prompt you to enter each API key securely."
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Wrangler CLI not found. Please install it first:"
    echo "npm install -g wrangler@latest"
    exit 1
fi

echo "📝 Setting up API keys as secrets..."
echo ""

# Set up each API key as a secret
echo "🔑 Setting AnyRouter API Key..."
wrangler secret put ANYROUTER_API_KEY

echo "🔑 Setting Gemini API Key..."
wrangler secret put GEMINI_API_KEY

echo "🔑 Setting OpenAI API Key..."
wrangler secret put OPENAI_API_KEY

echo "🔑 Setting Qwen API Key..."
wrangler secret put QWEN_API_KEY

# echo "🔑 Setting Claude API Key (optional, for fallback)..."
# wrangler secret put CLAUDE_API_KEY

echo ""
echo "✅ All secrets have been set up!"
echo "🚀 Your worker can now access the API keys securely."
echo ""
echo "💡 To update a secret later, run:"
echo "   wrangler secret put SECRET_NAME"
echo ""
echo "📋 To list all secrets, run:"
echo "   wrangler secret list"