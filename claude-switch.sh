#!/bin/bash

# Claude Provider Switcher - Easy switching between providers

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

show_usage() {
    echo -e "${CYAN}🔄 Claude Provider Switcher${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./claude-switch.sh [provider]"
    echo ""
    echo -e "${YELLOW}Available providers:${NC}"
    echo "  anyrouter    - AnyRouter direct (FREE, recommended)"
    echo "  gemini       - Google Gemini via worker proxy (FREE)"
    echo "  qwen         - Alibaba Qwen via worker proxy (FREE/Cheap)"
    echo "  status       - Show current provider"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./claude-switch.sh anyrouter"
    echo "  ./claude-switch.sh gemini"
    echo "  ./claude-switch.sh qwen"
    echo "  ./claude-switch.sh status"
    echo ""
    echo -e "${GREEN}💰 All providers offer significant cost savings vs official Claude API!${NC}"
}

case "$1" in
    anyrouter)
        ./claude-use-anyrouter.sh
        ;;
    gemini)
        ./claude-use-gemini.sh
        ;;
    qwen)
        ./claude-use-qwen.sh
        ;;
    status)
        ./claude-which.sh
        ;;
    "")
        show_usage
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Unknown provider: $1${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac