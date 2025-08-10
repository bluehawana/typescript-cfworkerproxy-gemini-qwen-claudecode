# Environment Setup Guide

This guide explains how to securely configure API keys for the multi-provider Claude proxy.

## Local Development

### 1. Create Environment File

Copy the example environment file:
```bash
cp .env.example .env.local
```

### 2. Add Your API Keys

Edit `.env.local` and add your actual API keys:
```bash
# AnyRouter API Key
ANYROUTER_API_KEY=sk-your_actual_anyrouter_key

# Gemini API Key  
GEMINI_API_KEY=your_actual_gemini_key

# OpenAI API Key
OPENAI_API_KEY=sk-your_actual_openai_key

# Qwen API Key
QWEN_API_KEY=sk-your_actual_qwen_key

# Claude API Key (optional)
CLAUDE_API_KEY=sk-ant-your_actual_claude_key
```

### 3. Security Note

- `.env.local` is already in `.gitignore` and will NOT be committed to git
- Never commit actual API keys to version control
- Use `.env.example` as a template for others

## Production Deployment

### Option 1: Automated Setup (Recommended)

Run the setup script to securely add all API keys:
```bash
./setup-secrets.sh
```

This will prompt you to enter each API key securely.

### Option 2: Manual Setup

Set each API key individually using Wrangler:
```bash
# AnyRouter
wrangler secret put ANYROUTER_API_KEY

# Gemini
wrangler secret put GEMINI_API_KEY

# OpenAI
wrangler secret put OPENAI_API_KEY

# Qwen
wrangler secret put QWEN_API_KEY

# Claude (optional)
wrangler secret put CLAUDE_API_KEY
```

### Managing Secrets

**List all secrets:**
```bash
wrangler secret list
```

**Update a secret:**
```bash
wrangler secret put SECRET_NAME
```

**Delete a secret:**
```bash
wrangler secret delete SECRET_NAME
```

## API Key Sources

### AnyRouter
- Website: https://anyrouter.top
- Get your API key from the dashboard
- Format: `sk-...`

### Gemini (Google)
- Website: https://makersuite.google.com/app/apikey
- Create a new API key
- Format: Usually starts with letters/numbers

### OpenAI
- Website: https://platform.openai.com/api-keys
- Create a new secret key
- Format: `sk-...`

### Qwen (Alibaba Cloud)
- Website: https://dashscope.console.aliyun.com/
- Get API key from DashScope console
- Format: `sk-...`

### Claude (Anthropic)
- Website: https://console.anthropic.com/
- Create API key in console
- Format: `sk-ant-...`

## Testing Your Setup

After setting up your keys, test each provider:

```bash
# Test AnyRouter
curl -X POST "https://claude-worker-proxy.bluehawana.workers.dev/anyrouter/anyrouter.top/v1/messages" \
  -H "x-api-key: YOUR_ANYROUTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","messages":[{"role":"user","content":"Hello"}]}'

# Test Gemini
curl -X POST "https://claude-worker-proxy.bluehawana.workers.dev/gemini/generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent/v1/messages" \
  -H "x-api-key: YOUR_GEMINI_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-3-5-sonnet","messages":[{"role":"user","content":"Hello"}]}'
```

## Security Best Practices

1. **Never commit API keys** to version control
2. **Use different keys** for development and production
3. **Rotate keys regularly** for security
4. **Monitor usage** to detect unauthorized access
5. **Use least privilege** - only grant necessary permissions
6. **Keep keys confidential** - don't share in chat, email, etc.

## Troubleshooting

### "Missing API key" errors
- Ensure secrets are set in Cloudflare Workers
- Check secret names match exactly (case-sensitive)
- Verify the worker has been redeployed after setting secrets

### "Invalid API key" errors
- Verify the API key is correct and active
- Check if the key has necessary permissions
- Ensure the key hasn't expired or been revoked

### Local development issues
- Make sure `.env.local` exists and has correct keys
- Restart your development server after changing environment variables