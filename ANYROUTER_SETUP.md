# AnyRouter Claude Setup

AnyRouter provides free Claude API access. Here are two ways to use it:

## Method 1: Direct Claude CLI (Recommended)

This is the simplest approach - use AnyRouter directly with the official Claude CLI:

### Quick Start

```bash
# One-time setup (if not already done)
./anyrouter-claude.sh -p "Hello, test message"

# Interactive mode
./anyrouter-interactive.sh
```

### Manual Setup

```bash
# Set environment variables
export ANTHROPIC_AUTH_TOKEN="your-anyrouter-api-key"
export ANTHROPIC_BASE_URL="https://anyrouter.top"

# Use Claude CLI normally
claude -p "Your prompt here"
claude  # Interactive mode
```

### Benefits
- ✅ No anti-bot protection issues
- ✅ Full Claude CLI functionality
- ✅ Interactive and non-interactive modes
- ✅ All Claude CLI features work
- ✅ Simple setup

## Method 2: Worker Proxy (Advanced)

Use our multi-provider worker proxy (currently blocked by AnyRouter's anti-bot protection):

```bash
curl -X POST "https://claude-worker-proxy.bluehawana.workers.dev/anyrouter/anyrouter.top/v1/messages" \
  -H "x-api-key: your-anyrouter-api-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","messages":[{"role":"user","content":"Hello"}]}'
```

**Status**: Currently blocked by anti-bot protection (returns HTML/JavaScript challenge)

## API Key Setup

1. Get your AnyRouter API key from https://anyrouter.top
2. Add it to `.env.local`:
   ```bash
   ANYROUTER_API_KEY=sk-your-key-here
   ```

## Usage Examples

### Non-interactive (one-shot)
```bash
./anyrouter-claude.sh -p "Explain quantum computing"
./anyrouter-claude.sh -p "Write a Python function to sort a list"
```

### Interactive session
```bash
./anyrouter-interactive.sh
# Then chat normally in the interactive session
```

### With specific model
```bash
./anyrouter-claude.sh --model sonnet -p "Your prompt"
```

## Cost Savings

- **AnyRouter**: Free tier available
- **Official Claude API**: $15-75 per million tokens
- **Savings**: Significant cost reduction for development and testing

## Troubleshooting

### "ANYROUTER_API_KEY not found"
- Make sure `.env.local` exists and contains your API key
- Check the key format: `ANYROUTER_API_KEY=sk-...`

### "Command not found: claude"
- Install Claude CLI: `npm install -g @anthropic-ai/claude-cli`
- Or use the installer from Anthropic's website

### Rate limits
- AnyRouter may have rate limits on free tier
- Consider upgrading to paid tier for higher limits