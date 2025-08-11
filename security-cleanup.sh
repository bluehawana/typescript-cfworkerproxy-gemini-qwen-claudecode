#!/bin/bash

# Security Cleanup - Remove API keys from git history

echo "🚨 SECURITY CLEANUP - Removing API keys from git history"
echo ""

# Add .env.local to .gitignore if not already there
if ! grep -q ".env.local" .gitignore 2>/dev/null; then
    echo ".env.local" >> .gitignore
    echo "✅ Added .env.local to .gitignore"
fi

# Add other sensitive files
cat >> .gitignore << EOF

# API Keys and Secrets
*.env
*.env.local
*.env.production
**/settings.json
**/.claude/settings.json

# Sensitive scripts
**/setup_claude_cli.sh
**/deploy_*_heroku.sh

EOF

echo "✅ Updated .gitignore with sensitive files"

# Remove sensitive files from current commit
git rm --cached .env.local 2>/dev/null || true
git rm --cached ~/.claude/settings.json 2>/dev/null || true

echo ""
echo "🔄 Next steps:"
echo "1. Revoke all exposed API keys from provider dashboards"
echo "2. Generate new API keys"
echo "3. Update .env.local with new keys (will be ignored by git)"
echo "4. Commit the .gitignore changes"
echo "5. Consider using git filter-branch to clean history"

echo ""
echo "⚠️  CRITICAL: Revoke these keys immediately:"
echo "   - AnyRouter: sk-0tLHsbD4IpO7bMfzuZSDh0V6JVQ8Ng39TBFIMywpStkXMjQ3"
echo "   - AnyRouter: sk-wldqMp1L48Uh85iQWgv05sRuUgtZxqyJAH92mW476z0SyiG4"  
echo "   - Qwen: sk-adfaf77b469b4975babd846aae3bf896"