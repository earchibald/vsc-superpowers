#!/usr/bin/env bash
# Test that verification markers are created by test runners

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source verification library
source "$SCRIPT_DIR/verification-lib.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_file_exists() {
    local file="$1"
    local message="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  File not found: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ ! -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  File exists but shouldn't: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo "========================================"
echo "Verification Marker Integration Tests"
echo "========================================"
echo ""

# Get project hash for this workspace
PROJECT_HASH=$(get_project_hash "$PROJECT_ROOT")
MARKER_FILE="/tmp/.superpowers-verified-${PROJECT_HASH}"

# Clean up before tests
rm -f "$MARKER_FILE"

# Test 1: Verification library can be sourced
echo "Test 1: Verification library loads"
if type get_project_hash >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} get_project_hash function available"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} get_project_hash function available"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 2: create_verification_marker creates marker
echo ""
echo "Test 2: create_verification_marker creates file"
rm -f "$MARKER_FILE"
create_verification_marker "$PROJECT_ROOT" >/dev/null 2>&1
assert_file_exists "$MARKER_FILE" "Marker created by library function"

# Test 3: Marker contains valid timestamp
echo ""
echo "Test 3: Marker contains valid timestamp"
if [ -f "$MARKER_FILE" ]; then
    content=$(cat "$MARKER_FILE")
    if [[ "$content" =~ ^[0-9]+$ ]]; then
        echo -e "${GREEN}✓${NC} Marker contains numeric timestamp"
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Marker contains numeric timestamp"
        echo "  Content: $content"
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}✗${NC} Marker file doesn't exist"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 4: remove_verification_marker removes marker
echo ""
echo "Test 4: remove_verification_marker removes file"
create_verification_marker "$PROJECT_ROOT" >/dev/null 2>&1
remove_verification_marker "$PROJECT_ROOT"
assert_file_not_exists "$MARKER_FILE" "Marker removed by library function"

# Test 5: check_verification_status works correctly
echo ""
echo "Test 5: check_verification_status detects recent marker"
create_verification_marker "$PROJECT_ROOT" >/dev/null 2>&1
set +e
status=$(check_verification_status "$PROJECT_ROOT")
set -e
if [ "$status" = "recent" ]; then
    echo -e "${GREEN}✓${NC} Verification status check works"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Verification status check works"
    echo "  Expected: recent"
    echo "  Got: $status"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 6: Master test runner sources library
echo ""
echo "Test 6: Master test runner sources verification-lib.sh"
if grep -q "source.*verification-lib.sh" "$SCRIPT_DIR/run-all-tests.sh"; then
    echo -e "${GREEN}✓${NC} Master test runner sources library"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Master test runner sources library"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 7: Master test runner creates marker on success
echo ""
echo "Test 7: Master test runner calls create_verification_marker"
if grep -q "create_verification_marker" "$SCRIPT_DIR/run-all-tests.sh"; then
    echo -e "${GREEN}✓${NC} Master test runner creates marker on success"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Master test runner creates marker on success"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 8: Master test runner removes marker on failure
echo ""
echo "Test 8: Master test runner calls remove_verification_marker"
if grep -q "remove_verification_marker" "$SCRIPT_DIR/run-all-tests.sh"; then
    echo -e "${GREEN}✓${NC} Master test runner removes marker on failure"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Master test runner removes marker on failure"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Cleanup
rm -f "$MARKER_FILE"

# Summary
echo ""
echo "========================================"
echo "Results:"
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo "========================================"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
