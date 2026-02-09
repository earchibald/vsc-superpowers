#!/usr/bin/env bash
# Test suite for hooks.json manifest

set -euo pipefail

# Test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_JSON="$PROJECT_ROOT/.github/hooks/hooks.json"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

echo "========================================"
echo "Testing hooks.json Manifest"
echo "========================================"

# Test 1: hooks.json exists
echo ""
echo "Test 1: hooks.json file exists"
if [ -f "$HOOKS_JSON" ]; then
    echo -e "${GREEN}✓${NC} hooks.json exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} hooks.json missing at .github/hooks/hooks.json"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 2: hooks.json is valid JSON
echo ""
echo "Test 2: hooks.json is valid JSON"
if [ -f "$HOOKS_JSON" ]; then
    if command -v jq >/dev/null 2>&1; then
        if jq empty "$HOOKS_JSON" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Valid JSON structure"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗${NC} Invalid JSON"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        if python3 -m json.tool < "$HOOKS_JSON" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Valid JSON structure"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗${NC} Invalid JSON"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
else
    echo -e "${RED}✗${NC} Cannot validate - file missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 3: sessionStart hook registered
echo ""
echo "Test 3: sessionStart hook registered"
if [ -f "$HOOKS_JSON" ]; then
    if grep -q "sessionStart" "$HOOKS_JSON"; then
        echo -e "${GREEN}✓${NC} sessionStart hook found"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} sessionStart hook not registered"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}✗${NC} Cannot test - file missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 4: preToolUse hook registered
echo ""
echo "Test 4: preToolUse hook registered"
if [ -f "$HOOKS_JSON" ]; then
    if grep -q "preToolUse" "$HOOKS_JSON"; then
        echo -e "${GREEN}✓${NC} preToolUse hook found"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} preToolUse hook not registered"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}✗${NC} Cannot test - file missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 5: session-start.sh script referenced
echo ""
echo "Test 5: session-start.sh script referenced"
if [ -f "$HOOKS_JSON" ]; then
    if grep -q "session-start.sh" "$HOOKS_JSON"; then
        echo -e "${GREEN}✓${NC} session-start.sh referenced"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} session-start.sh not referenced"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}✗${NC} Cannot test - file missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 6: pre-command.sh script referenced
echo ""
echo "Test 6: pre-command.sh script referenced"
if [ -f "$HOOKS_JSON" ]; then
    if grep -q "pre-command.sh" "$HOOKS_JSON"; then
        echo -e "${GREEN}✓${NC} pre-command.sh referenced"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} pre-command.sh not referenced"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}✗${NC} Cannot test - file missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Summary
echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo "Tests run:    $TOTAL"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
