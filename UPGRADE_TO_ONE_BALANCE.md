# Upgrade to One-Balance System

Our current worker is basic. The one-balance project is much more sophisticated and production-ready.

## Why Upgrade?

### Current Issues:
- ❌ AnyRouter blocked by anti-bot protection
- ❌ High ban risk for API keys
- ❌ No intelligent error handling
- ❌ Manual provider switching
- ❌ No key management

### One-Balance Benefits:
- ✅ **Lower ban risk** - Routes through Cloudflare AI Gateway
- ✅ **Smart error handling** - Model-level rate limiting with cooling periods
- ✅ **Auto circuit breaker** - Permanently disables banned keys (403 errors)
- ✅ **Key management UI** - Web interface to add/manage keys
- ✅ **Better observability** - Logs and analytics via CF AI Gateway
- ✅ **Production ready** - Used in real applications like zenfeed.xyz

## Setup Steps

### 1. Create Cloudflare AI Gateway
1. Login to Cloudflare Dashboard
2. Navigate to AI → AI Gateway
3. Create new gateway named `one-balance`

### 2. Deploy One-Balance
```bash
# Clone the real one-balance project
git clone https://github.com/glidea/one-balance.git
cd one-balance
pnpm install

# Deploy with auth key
AUTH_KEY="your-super-secret-auth-key" pnpm run deploycf
```

### 3. Configure API Keys
1. Access your worker URL: `https://one-balance-backend.<subdomain>.workers.dev`
2. Add your API keys through the web interface:
   - AnyRouter API key
   - Gemini API key  
   - Qwen API key
   - OpenAI API key (if you have one)

### 4. Usage Examples

#### Direct Gemini (Recommended)
```bash
curl "https://<worker-url>/api/google-ai-studio/v1/models/gemini-2.5-flash:streamGenerateContent?alt=sse" \
  -H 'content-type: application/json' \
  -H 'x-goog-api-key: your-super-secret-auth-key' \
  -d '{
    "contents": [{
      "role":"user", 
      "parts": [{"text":"Hello"}]
    }]
  }'
```

#### OpenAI Compatible Format
```bash
curl "https://<worker-url>/api/compat/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-super-secret-auth-key" \
  -d '{
    "model": "google-ai-studio/gemini-2.5-pro",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### 5. Claude Code Integration
Update `~/.claude/settings.json`:
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://<worker-url>/api/compat",
    "ANTHROPIC_API_KEY": "your-super-secret-auth-key",
    "ANTHROPIC_MODEL": "google-ai-studio/gemini-2.5-pro"
  }
}
```

## Key Features

### Smart Error Handling
- **Model-level cooling**: Only cools specific models, not entire keys
- **Intelligent timeouts**: 1min for rate limits, 24h for quota limits
- **Auto circuit breaker**: Permanently disables banned keys

### Key Management
- **Web UI**: Easy key management interface
- **Batch operations**: Add multiple keys at once
- **Status monitoring**: See which keys are active/blocked

### Observability
- **CF AI Gateway analytics**: Request counts, error rates, costs
- **Worker logs**: Key events and errors
- **Real-time status**: Current key health

## Migration Plan

1. **Deploy one-balance** alongside current worker
2. **Test with one provider** (e.g., Gemini)
3. **Add all API keys** through web interface
4. **Update Claude Code** to use new endpoint
5. **Retire old worker** once stable

This gives us a production-ready system with proper error handling and key management!