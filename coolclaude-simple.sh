#!/bin/bash

# CoolClaude Simple - Direct free token Claude interface

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to show usage
show_usage() {
    echo -e "${CYAN}🆒 CoolClaude - Free Token Claude Interface${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  coolclaude [options] \"your prompt here\""
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -anyrouter                              Start AnyRouter Claude CLI directly"
    echo "  -h, --help                              Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  coolclaude -anyrouter                   # Start AnyRouter Claude CLI"
    echo ""
    echo -e "${GREEN}💰 Cost: FREE tokens! No paid Claude API needed!${NC}"
}

# Main logic
case "$1" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -anyrouter)
        echo -e "${CYAN}🚀 Starting AnyRouter Claude CLI...${NC}"
        echo -e "${GREEN}💡 This uses the official Claude CLI with AnyRouter backend${NC}"
        echo ""
        # Execute the anyrouter interactive script
        exec "${SCRIPT_DIR}/anyrouter-interactive.sh"
        ;;
    "")
        show_usage
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Unknown option: $1${NC}"
        show_usage
        exit 1
        ;;
esac