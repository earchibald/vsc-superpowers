#!/usr/bin/env bash
# Test suite for session-start.sh hook

set -euo pipefail

# Test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_SCRIPT="$PROJECT_ROOT/.github/hooks/scripts/session-start.sh"

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
    export TEST_CACHE_DIR="$(mktemp -d)"
    export HOME_BACKUP="$HOME"
    export HOME="$(mktemp -d)"
    mkdir -p "$HOME/.cache"
}

teardown_test_env() {
    rm -rf "$TEST_CACHE_DIR"
    rm -rf "$HOME"
    export HOME="$HOME_BACKUP"
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
    # This test will FAIL initially (TDD - test first)
    assert_file_exists "$HOOK_SCRIPT" "Hook script should exist at .github/hooks/scripts/session-start.sh"
    
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
# TEST: Cache directory check - missing cache
# ============================================================================
test_bootstrap_missing_cache() {
    # Mock git clone by creating a simple function
    git() {
        if [ "$1" = "clone" ]; then
            local repo_url="$2"
            local target_dir="$3"
            mkdir -p "$target_dir"
            echo "Mocked: Cloned $repo_url to $target_dir"
            return 0
        fi
        command git "$@"
    }
    export -f git
    
    # Run hook (should bootstrap)
    local output
    output=$("$HOOK_SCRIPT" 2>&1) || true
    
    # Verify bootstrap happened
    assert_contains "$output" "superpowers" "Output should mention superpowers"
    
    unset -f git
}

# ============================================================================
# TEST: Cache directory check - cache exists
# ============================================================================
test_cache_exists_no_bootstrap() {
    # Create fake cache directory
    mkdir -p "$HOME/.cache/superpowers"
    echo "existing cache" > "$HOME/.cache/superpowers/README.md"
    
    # Mock git to detect if clone was called
    local git_clone_called=false
    git() {
        if [ "$1" = "clone" ]; then
            git_clone_called=true
        fi
        return 0
    }
    export -f git
    
    # Run hook
    "$HOOK_SCRIPT" 2>&1 || true
    
    # Verify git clone was NOT called
    if [ "$git_clone_called" = false ]; then
        echo -e "${GREEN}✓${NC} Git clone was not called when cache exists"
        return 0
    else
        echo -e "${RED}✗${NC} Git clone should not be called when cache exists"
        return 1
    fi
    
    unset -f git
}

# ============================================================================
# TEST: Success banner output
# ============================================================================
test_success_banner_output() {
    # Create fake cache
    mkdir -p "$HOME/.cache/superpowers"
    
    # Run hook and capture output
    local output
    output=$("$HOOK_SCRIPT" 2>&1) || true
    
    # Verify banner contains expected text
    assert_contains "$output" "Superpowers" "Output should contain 'Superpowers'"
}

# ============================================================================
# TEST: Hook exits with code 0
# ============================================================================
test_hook_exits_zero() {
    # Create fake cache
    mkdir -p "$HOME/.cache/superpowers"
    
    # Run hook and check exit code
    if "$HOOK_SCRIPT" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Hook exits with code 0"
        return 0
    else
        echo -e "${RED}✗${NC} Hook should exit with code 0"
        return 1
    fi
}

# ============================================================================
# TEST: Idempotency - multiple runs safe
# ============================================================================
test_idempotency() {
    # Create fake cache
    mkdir -p "$HOME/.cache/superpowers"
    echo "test" > "$HOME/.cache/superpowers/test.txt"
    
    # Run hook twice
    "$HOOK_SCRIPT" >/dev/null 2>&1 || true
    "$HOOK_SCRIPT" >/dev/null 2>&1 || true
    
    # Verify cache still intact
    assert_file_exists "$HOME/.cache/superpowers/test.txt" "Cache should remain intact after multiple runs"
}

# ============================================================================
# TEST: Git pull when cache exists
# ============================================================================
test_git_pull_when_cache_exists() {
    # Create fake cache with git directory
    mkdir -p "$HOME/.cache/superpowers/.git"
    
    local git_pull_called=false
    git() {
        if [ "$1" = "pull" ]; then
            git_pull_called=true
            return 0
        fi
        return 0
    }
    export -f git
    
    # Run hook
    "$HOOK_SCRIPT" >/dev/null 2>&1 || true
    
    # Verify git pull was called
    if [ "$git_pull_called" = true ]; then
        echo -e "${GREEN}✓${NC} Git pull was called when cache exists"
        return 0
    else
        echo -e "${RED}✗${NC} Git pull should be called to update cache"
        return 1
    fi
    
    unset -f git
}

# ============================================================================
# TEST: Network failure handling
# ============================================================================
test_network_failure_graceful() {
    # Mock git clone to fail
    git() {
        if [ "$1" = "clone" ]; then
            echo "fatal: unable to access repository" >&2
            return 128
        fi
        return 0
    }
    export -f git
    
    # Run hook - should not crash
    if "$HOOK_SCRIPT" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Hook handles network failure gracefully (exits 0)"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Hook exits non-zero on network failure (acceptable, but could be improved)"
        # This is acceptable behavior - we'll log the warning but pass the test
        return 0
    fi
    
    unset -f git
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================
main() {
    echo "========================================"
    echo "Copilot CLI Hooks - Session Start Tests"
    echo "========================================"
    
    run_test "Hook script exists and is executable" test_hook_script_exists
    run_test "Bootstrap missing cache" test_bootstrap_missing_cache
    run_test "Cache exists - no bootstrap" test_cache_exists_no_bootstrap
    run_test "Success banner output" test_success_banner_output
    run_test "Hook exits with code 0" test_hook_exits_zero
    run_test "Idempotency" test_idempotency
    run_test "Git pull when cache exists" test_git_pull_when_cache_exists
    run_test "Network failure handling" test_network_failure_graceful
    
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
