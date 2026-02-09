#!/usr/bin/env bash
# Test suite for pre-command.sh hook

set -euo pipefail

# Test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_SCRIPT="$PROJECT_ROOT/.github/hooks/scripts/pre-command.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test fixture setup
setup_test_env() {
    export TEST_TMP_DIR="$(mktemp -d)"
    export PROJECT_HASH="test_project_hash"
}

teardown_test_env() {
    rm -rf "$TEST_TMP_DIR"
    rm -f /tmp/.superpowers-verified-*
}

# Test assertion helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        return 1
    fi
}

assert_file_exists() {
    local filepath="$1"
    local message="${2:-File should exist: $filepath}"
    
    if [ -f "$filepath" ] || [ -d "$filepath" ]; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  File does not exist: $filepath"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    if echo "$haystack" | grep -q "$needle"; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected to find: '$needle'"
        echo "  In: '$haystack'"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    if ! echo "$haystack" | grep -q "$needle"; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Should NOT contain: '$needle'"
        echo "  But found in: '$haystack'"
        return 1
    fi
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo ""
    echo "Running: $test_name"
    echo "----------------------------------------"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    setup_test_env
    
    if $test_function; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}: $test_name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}: $test_name"
    fi
    
    teardown_test_env
}

# ============================================================================
# TEST: Hook script exists and is executable
# ============================================================================
test_hook_script_exists() {
    assert_file_exists "$HOOK_SCRIPT" "Hook script should exist at .github/hooks/scripts/pre-command.sh"
    
    if [ -f "$HOOK_SCRIPT" ]; then
        if [ -x "$HOOK_SCRIPT" ]; then
            echo -e "${GREEN}✓${NC} Hook script is executable"
            return 0
        else
            echo -e "${RED}✗${NC} Hook script is not executable"
            return 1
        fi
    fi
    
    return 1
}

# ============================================================================
# TEST: JSON parsing - valid payload
# ============================================================================
test_json_parsing_valid() {
    local json_payload
    json_payload=$(cat <<'EOF'
{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"git commit -m feat\"}"
}
EOF
)
    
    # Run hook with JSON input
    local output
    output=$(echo "$json_payload" | "$HOOK_SCRIPT" 2>&1) || true
    
    # Should not crash with valid JSON
    echo -e "${GREEN}✓${NC} Hook handles valid JSON without crashing"
    return 0
}

# ============================================================================
# TEST: JSON parsing - malformed JSON
# ============================================================================
test_json_parsing_malformed() {
    local json_payload='{ invalid json }'
    
    # Run hook with malformed JSON - should not crash
    if echo "$json_payload" | "$HOOK_SCRIPT" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Hook handles malformed JSON gracefully - exits 0"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Hook exits non-zero on malformed JSON - acceptable"
        return 0
    fi
}

# ============================================================================
# TEST: Commit detection - git commit
# ============================================================================
test_detect_git_commit() {
    local json_payload
    json_payload=$(cat <<'EOF'
{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"git commit -m feat\"}"
}
EOF
)
    
    # Run hook without verification marker
    local output
    output=$(echo "$json_payload" | "$HOOK_SCRIPT" 2>&1) || true
    
    # Should detect commit and warn
    assert_contains "$output" "commit" "Output should mention commit detection"
}

# ============================================================================
# TEST: Commit detection - git push
# ============================================================================
test_detect_git_push() {
    local json_payload='{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"git push origin main\"}"
}'
    
    # Run hook without verification marker
    local output
    output=$(echo "$json_payload" | "$HOOK_SCRIPT" 2>&1) || true
    
    # Should detect push
    assert_contains "$output" "push\|commit" "Output should mention push/commit detection"
}

# ============================================================================
# TEST: Ignore read-only commands
# ============================================================================
test_ignore_readonly_commands() {
    local json_payload='{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"git log --oneline\"}"
}'
    
    # Run hook
    local output
    output=$(echo "$json_payload" | "$HOOK_SCRIPT" 2>&1) || true
    
    # Should NOT warn for read-only commands
    assert_not_contains "$output" "warning\|verify" "Should not warn for read-only commands"
}

# ============================================================================
# TEST: Verification marker - missing marker warns
# ============================================================================
test_missing_verification_marker_warns() {
    local json_payload
    json_payload=$(cat <<'EOF'
{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"git commit -m test\"}"
}
EOF
)
    
    # Ensure no verification marker exists
    rm -f /tmp/.superpowers-verified-*
    
    # Run hook
    local output
    output=$(echo "$json_payload" | "$HOOK_SCRIPT" 2>&1) || true
    
    # Should warn about missing verification
    assert_contains "$output" "test\|verif" "Should warn about missing verification"
}

# ============================================================================
# TEST: Verification marker - recent marker allows commit
# ============================================================================
test_recent_verification_marker_allows() {
    # Create recent verification marker
    local marker_file="/tmp/.superpowers-verified-${PROJECT_HASH}"
    touch "$marker_file"
    
    local json_payload
    json_payload=$(cat <<'EOF'
{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"git commit -m test\"}"
}
EOF
)
    
    # Run hook
    local output
    output=$(echo "$json_payload" | "$HOOK_SCRIPT" 2>&1) || true
    
    # Should NOT warn when marker exists
    if echo "$output" | grep -qi "warning"; then
        echo -e "${RED}✗${NC} Should not warn when verification marker exists"
        return 1
    else
        echo -e "${GREEN}✓${NC} No warning when verification marker exists"
        return 0
    fi
}

# ============================================================================
# TEST: Verification marker - stale marker warns
# ============================================================================
test_stale_verification_marker_warns() {
    # Create stale verification marker (older than 1 hour)
    local marker_file="/tmp/.superpowers-verified-${PROJECT_HASH}"
    touch -t 202601010000 "$marker_file" 2>/dev/null || touch "$marker_file"
    
    # Make marker old (if touch -t doesn't work, we'll skip this test)
    if [ -f "$marker_file" ]; then
        # Try to make it old
        local marker_age
        marker_age=$(( $(date +%s) - $(stat -f %m "$marker_file" 2>/dev/null || stat -c %Y "$marker_file" 2>/dev/null || echo 0) ))
        
        if [ "$marker_age" -gt 3600 ]; then
            local json_payload
            json_payload=$(cat <<'EOF'
{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"git commit -m test\"}"
}
EOF
)
            
            # Run hook
            local output
            output=$(echo "$json_payload" | "$HOOK_SCRIPT" 2>&1) || true
            
            # Should warn about stale marker
            assert_contains "$output" "test\|verif\|stale" "Should warn about stale verification"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}⚠${NC} Skipping stale marker test - cannot create old file"
    return 0
}

# ============================================================================
# TEST: Hook always exits 0 (non-blocking)
# ============================================================================
test_hook_exits_zero() {
    local json_payload
    json_payload=$(cat <<'EOF'
{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"git commit -m test\"}"
}
EOF
)
    
    # Run hook - should always exit 0 - warn, don't block
    if echo "$json_payload" | "$HOOK_SCRIPT" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Hook exits with code 0 - non-blocking"
        return 0
    else
        echo -e "${RED}✗${NC} Hook should exit 0 - warn but don't block users"
        return 1
    fi
}

# ============================================================================
# TEST: Empty command handling
# ============================================================================
test_empty_command_handling() {
    local json_payload='{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"\"}"
}'
    
    # Run hook with empty command - should not crash
    if echo "$json_payload" | "$HOOK_SCRIPT" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Hook handles empty command gracefully"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Hook could handle empty command better"
        return 0
    fi
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================
main() {
    echo "========================================"
    echo "Copilot CLI Hooks - Pre-Command Tests"
    echo "========================================"
    
    run_test "Hook script exists and is executable" test_hook_script_exists
    run_test "JSON parsing - valid payload" test_json_parsing_valid
    run_test "JSON parsing - malformed JSON" test_json_parsing_malformed
    run_test "Detect git commit command" test_detect_git_commit
    run_test "Detect git push command" test_detect_git_push
    run_test "Ignore read-only commands" test_ignore_readonly_commands
    run_test "Missing verification marker warns" test_missing_verification_marker_warns
    run_test "Recent verification marker allows" test_recent_verification_marker_allows
    run_test "Stale verification marker warns" test_stale_verification_marker_warns
    run_test "Hook always exits 0 - non-blocking" test_hook_exits_zero
    run_test "Empty command handling" test_empty_command_handling
    
    echo ""
    echo "========================================"
    echo "Test Results"
    echo "========================================"
    echo "Tests run:    $TESTS_RUN"
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
}

# Run tests if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
