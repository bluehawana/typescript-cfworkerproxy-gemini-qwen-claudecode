#!/bin/bash

# Test All Scripts - Comprehensive testing suite

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0
TOTAL=0

# Function to run test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_pattern="$3"
    
    echo -e "${BLUE}🧪 Testing: $test_name${NC}"
    echo -e "${YELLOW}   Command: $command${NC}"
    
    TOTAL=$((TOTAL + 1))
    
    # Run command and capture output
    local output
    if output=$(eval "$command" 2>&1); then
        if [[ -z "$expected_pattern" ]] || echo "$output" | grep -q "$expected_pattern"; then
            echo -e "${GREEN}   ✅ PASSED${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}   ❌ FAILED - Expected pattern not found: $expected_pattern${NC}"
            echo -e "${YELLOW}   Output: ${output:0:200}...${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${RED}   ❌ FAILED - Command execution error${NC}"
        echo -e "${YELLOW}   Error: ${output:0:200}...${NC}"
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

# Function to test script exists and is executable
test_script_exists() {
    local script="$1"
    local description="$2"
    
    echo -e "${BLUE}📁 Checking: $description${NC}"
    echo -e "${YELLOW}   Script: $script${NC}"
    
    TOTAL=$((TOTAL + 1))
    
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}   ✅ PASSED - Script exists and is executable${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}   ❌ FAILED - Script exists but not executable${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${RED}   ❌ FAILED - Script does not exist${NC}"
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

# Function to test API endpoint
test_api_endpoint() {
    local name="$1"
    local url="$2"
    local headers="$3"
    
    echo -e "${BLUE}🌐 Testing API: $name${NC}"
    echo -e "${YELLOW}   URL: $url${NC}"
    
    TOTAL=$((TOTAL + 1))
    
    local response
    if response=$(curl -s -w "%{http_code}" -o /dev/null $headers "$url" 2>&1); then
        if [[ "$response" =~ ^[0-9]+$ ]]; then
            if [ "$response" -lt 500 ]; then
                echo -e "${GREEN}   ✅ PASSED - API responding (HTTP $response)${NC}"
                PASSED=$((PASSED + 1))
            else
                echo -e "${YELLOW}   ⚠️  WARNING - API error (HTTP $response)${NC}"
                PASSED=$((PASSED + 1))
            fi
        else
            echo -e "${RED}   ❌ FAILED - Invalid response: $response${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${RED}   ❌ FAILED - Connection error${NC}"
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

echo -e "${CYAN}🚀 Starting Comprehensive Script Testing${NC}"
echo -e "${PURPLE}================================================${NC}"
echo ""

# Test 1: Check if all scripts exist and are executable
echo -e "${PURPLE}📋 Phase 1: Script Existence and Permissions${NC}"
echo ""

test_script_exists "./claude-manager.sh" "Claude Manager"
test_script_exists "./direct-api-chat.sh" "Direct API Chat"
test_script_exists "./hybrid-chat.sh" "Hybrid Chat"
test_script_exists "./balance-chat.sh" "Balance Chat"
test_script_exists "./test-one-balance.sh" "One-Balance Test"
test_script_exists "./coolclaude-anyrouter.sh" "CoolClaude AnyRouter"
test_script_exists "./coolclaude-gemini.sh" "CoolClaude Gemini"
test_script_exists "./coolclaude-qwen.sh" "CoolClaude Qwen"

# Test 2: Check configuration files
echo -e "${PURPLE}📋 Phase 2: Configuration Files${NC}"
echo ""

test_script_exists "./.env.local" "Environment Variables"
test_script_exists "./wrangler.toml" "Wrangler Config"

# Test 3: Test script help/usage functions
echo -e "${PURPLE}📋 Phase 3: Script Help Functions${NC}"
echo ""

run_test "Claude Manager Help" "./claude-manager.sh" "Claude Manager"
run_test "Claude Manager Status" "./claude-manager.sh status" "Current Claude Configuration"

# Test 4: Test API endpoints
echo -e "${PURPLE}📋 Phase 4: API Endpoints${NC}"
echo ""

test_api_endpoint "One-Balance Web UI" "https://one-balance.bluehawana.workers.dev" ""
test_api_endpoint "Custom Worker" "https://claude-worker-proxy.bluehawana.workers.dev" ""

# Test 5: Test direct API calls (if API keys available)
echo -e "${PURPLE}📋 Phase 5: Direct API Tests${NC}"
echo ""

if [ -f .env.local ]; then
    source .env.local
    
    if [ ! -z "$GEMINI_API_KEY" ]; then
        test_api_endpoint "Gemini Direct API" \
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$GEMINI_API_KEY" \
            "-H 'Content-Type: application/json' -d '{\"contents\":[{\"role\":\"user\",\"parts\":[{\"text\":\"ping\"}]}]}'"
    else
        echo -e "${YELLOW}⚠️  Skipping Gemini test - No API key${NC}"
        echo ""
    fi
    
    if [ ! -z "$QWEN_API_KEY" ]; then
        test_api_endpoint "Qwen Direct API" \
            "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation" \
            "-H 'Authorization: Bearer $QWEN_API_KEY' -H 'Content-Type: application/json' -d '{\"model\":\"qwen-max\",\"input\":{\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}]}}'"
    else
        echo -e "${YELLOW}⚠️  Skipping Qwen test - No API key${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  Skipping API tests - No .env.local file${NC}"
    echo ""
fi

# Test 6: Test environment switching
echo -e "${PURPLE}📋 Phase 6: Environment Switching${NC}"
echo ""

run_test "Backup Settings" "./claude-manager.sh backup" "backed up"
run_test "Switch to Free Mode" "./claude-manager.sh free" "Switched to Free"
run_test "Switch to Official Mode" "./claude-manager.sh official" "Switched to Official"

# Summary
echo -e "${PURPLE}================================================${NC}"
echo -e "${CYAN}📊 Test Results Summary${NC}"
echo ""
echo -e "${GREEN}✅ Passed: $PASSED${NC}"
echo -e "${RED}❌ Failed: $FAILED${NC}"
echo -e "${BLUE}📊 Total:  $TOTAL${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Your system is ready to use.${NC}"
    echo ""
    echo -e "${CYAN}💡 Quick Start:${NC}"
    echo "  ./claude-manager.sh status    # Check current setup"
    echo "  ./claude-manager.sh free      # Switch to free APIs"
    echo "  ./direct-api-chat.sh          # Start free chat"
    echo ""
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check the errors above.${NC}"
    echo ""
    echo -e "${CYAN}💡 Common fixes:${NC}"
    echo "  chmod +x *.sh                # Make scripts executable"
    echo "  ./claude-manager.sh status    # Check configuration"
    echo ""
fi

echo -e "${PURPLE}================================================${NC}"