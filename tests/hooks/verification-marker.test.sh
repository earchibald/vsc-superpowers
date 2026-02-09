#!/usr/bin/env bash
# Tests for verification marker creation and management

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

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

# Helper: Get project hash for current directory
get_project_hash() {
    local project_dir="${1:-$PROJECT_ROOT}"
    echo -n "$project_dir" | md5sum | cut -d' ' -f1 2>/dev/null || \
    echo -n "$project_dir" | md5 | cut -d' ' -f1 2>/dev/null
}

# Helper: Create verification marker
create_verification_marker() {
    local project_dir="${1:-$PROJECT_ROOT}"
    local project_hash
    project_hash=$(get_project_hash "$project_dir")
    local marker_file="/tmp/.superpowers-verified-${project_hash}"
    
    date +%s > "$marker_file"
    echo "$marker_file"
}

# Helper: Check if marker exists and is recent
check_marker_age() {
    local marker_file="$1"
    local max_age="${2:-3600}"  # Default 1 hour
    
    if [ ! -f "$marker_file" ]; then
        echo "missing"
        return 1
    fi
    
    local marker_time
    marker_time=$(cat "$marker_file")
    local current_time
    current_time=$(date +%s)
    local age=$((current_time - marker_time))
    
    if [ $age -lt $max_age ]; then
        echo "recent"
        return 0
    else
        echo "stale"
        return 1
    fi
}

# Cleanup before tests
cleanup() {
    local project_hash
    project_hash=$(get_project_hash)
    rm -f "/tmp/.superpowers-verified-${project_hash}"
}

# Run cleanup before and after tests
cleanup

echo "========================================"
echo "Verification Marker Tests"
echo "========================================"
echo ""

# Test 1: Marker creation helper works
echo "Test 1: Marker creation helper creates file"
marker_file=$(create_verification_marker)
assert_file_exists "$marker_file" "Marker file created at expected path"

# Test 2: Marker contains timestamp
echo ""
echo "Test 2: Marker file contains valid timestamp"
if [ -f "$marker_file" ]; then
    marker_content=$(cat "$marker_file")
    # Check if it's a number
    if [[ "$marker_content" =~ ^[0-9]+$ ]]; then
        echo -e "${GREEN}✓${NC} Marker contains numeric timestamp"
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Marker contains numeric timestamp"
        echo "  Content: $marker_content"
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}✗${NC} Marker file doesn't exist, skipping content check"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 3: Recent marker is detected as recent
echo ""
echo "Test 3: Recently created marker detected as recent"
marker_file=$(create_verification_marker)
age_result=$(check_marker_age "$marker_file" 3600)
assert_equals "recent" "$age_result" "Marker age check returns 'recent'"

# Test 4: Stale marker is detected as stale
echo ""
echo "Test 4: Old marker detected as stale"
marker_file=$(create_verification_marker)
# Backdate the marker by 2 hours
old_timestamp=$(($(date +%s) - 7200))
echo "$old_timestamp" > "$marker_file"
# Disable pipefail for this check since function returns non-zero
set +e
age_result=$(check_marker_age "$marker_file" 3600)
set -e
assert_equals "stale" "$age_result" "Marker age check returns 'stale' for 2-hour-old marker"

# Test 5: Missing marker is detected
echo ""
echo "Test 5: Missing marker detected correctly"
cleanup  # Remove marker
marker_file="/tmp/.superpowers-verified-$(get_project_hash)"
# Disable pipefail for this check since function returns non-zero
set +e
age_result=$(check_marker_age "$marker_file" 3600)
set -e
assert_equals "missing" "$age_result" "Marker age check returns 'missing' when file absent"

# Test 6: Project hash is consistent
echo ""
echo "Test 6: Project hash calculation is consistent"
hash1=$(get_project_hash "$PROJECT_ROOT")
hash2=$(get_project_hash "$PROJECT_ROOT")
assert_equals "$hash1" "$hash2" "Same directory produces same hash"

# Test 7: Different directories produce different hashes
echo ""
echo "Test 7: Different directories produce different hashes"
hash1=$(get_project_hash "$PROJECT_ROOT")
hash2=$(get_project_hash "/tmp")
if [ "$hash1" != "$hash2" ]; then
    echo -e "${GREEN}✓${NC} Different directories produce different hashes"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Different directories produce different hashes"
    echo "  Both produced: $hash1"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 8: Marker cleanup works
echo ""
echo "Test 8: Marker cleanup removes file"
marker_file=$(create_verification_marker)
cleanup
assert_file_not_exists "$marker_file" "Marker file removed by cleanup"

# Cleanup after tests
cleanup

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
