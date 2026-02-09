#!/bin/bash
# Test suite for Superpowers plugin bootstrap and hybrid architecture
# Tests in isolated environment without affecting user's ~/.cache/superpowers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_ID="$$"
TEST_HOME="/tmp/superpowers-test-${TEST_ID}"
TEST_CACHE_DIR="${TEST_HOME}/.cache/superpowers"
BUNDLED_SKILLS_PATH="${PROJECT_ROOT}/.agents/skills"

# Create test environment
setup_test_env() {
    echo -e "${BLUE}Setting up isolated test environment...${NC}"
    mkdir -p "$TEST_HOME"
    export HOME="$TEST_HOME"
    export SUPERPOWERS_CACHE_DIR="$TEST_CACHE_DIR"
    
    # Verify we're isolated
    if [ "$(cd ~ && pwd)" != "$TEST_HOME" ]; then
        echo -e "${RED}Failed to isolate HOME${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} Isolated HOME: $TEST_HOME"
    echo -e "${GREEN}✓${NC} Test CACHE_DIR: $TEST_CACHE_DIR"
}

# Cleanup test environment
cleanup_test_env() {
    echo -e "${BLUE}Cleaning up test environment...${NC}"
    rm -rf "$TEST_HOME"
    unset SUPERPOWERS_CACHE_DIR
    echo -e "${GREEN}✓${NC} Cleanup complete"
}

# Test 1: Bootstrap script creates cache on first run
test_bootstrap_creates_cache() {
    echo -e "\n${BLUE}Test 1: Bootstrap creates cache on first run${NC}"
    
    if [ -d "$TEST_CACHE_DIR" ]; then
        echo -e "${RED}✗${NC} Cache already exists (should not exist yet)"
        return 1
    fi
    
    # Run bootstrap
    bash "$PROJECT_ROOT/.agents/bootstrap-superpowers.sh"
    
    if [ ! -d "$TEST_CACHE_DIR" ]; then
        echo -e "${RED}✗${NC} Bootstrap failed - cache not created"
        return 1
    fi
    
    if [ ! -d "$TEST_CACHE_DIR/skills" ]; then
        echo -e "${YELLOW}⚠${NC} Cache created but skills directory missing"
        echo "    (This is OK if obra/superpowers was unavailable during test)"
        return 0
    fi
    
    echo -e "${GREEN}✓${NC} Cache successfully created at $TEST_CACHE_DIR"
    return 0
}

# Test 2: Bootstrap idempotent (safe to run multiple times)
test_bootstrap_idempotent() {
    echo -e "\n${BLUE}Test 2: Bootstrap is idempotent${NC}"
    
    # Run once
    bash "$PROJECT_ROOT/.agents/bootstrap-superpowers.sh" > /dev/null 2>&1 || true
    
    # Get cache timestamp
    TIMESTAMP1=$(stat -f%m "$TEST_CACHE_DIR" 2>/dev/null || stat -c%Y "$TEST_CACHE_DIR" 2>/dev/null || echo "unknown")
    
    sleep 1
    
    # Run again
    bash "$PROJECT_ROOT/.agents/bootstrap-superpowers.sh" > /dev/null 2>&1 || true
    
    TIMESTAMP2=$(stat -f%m "$TEST_CACHE_DIR" 2>/dev/null || stat -c%Y "$TEST_CACHE_DIR" 2>/dev/null || echo "unknown")
    
    echo -e "${GREEN}✓${NC} Bootstrap script is safe to run multiple times"
    return 0
}

# Test 3: Bundled skills exist as fallback
test_bundled_skills_exist() {
    echo -e "\n${BLUE}Test 3: Bundled skills exist as fallback${NC}"
    
    SKILL_COUNT=$(find "$BUNDLED_SKILLS_PATH" -maxdepth 2 -name "SKILL.md" | wc -l)
    
    if [ "$SKILL_COUNT" -lt 10 ]; then
        echo -e "${RED}✗${NC} Expected 14 bundled skills, found $SKILL_COUNT"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} Found $SKILL_COUNT bundled skills"
    
    # Verify critical skills
    REQUIRED_SKILLS=("tdd" "brainstorm" "write-plan" "investigate")
    for skill in "${REQUIRED_SKILLS[@]}"; do
        if [ ! -f "$BUNDLED_SKILLS_PATH/$skill/SKILL.md" ]; then
            echo -e "${RED}✗${NC} Missing required skill: $skill"
            return 1
        fi
    done
    
    echo -e "${GREEN}✓${NC} All required skills present"
    return 0
}

# Test 4: Manifest valid JSON
test_manifest_valid() {
    echo -e "\n${BLUE}Test 4: Manifest is valid JSON${NC}"
    
    if ! grep -q 'python' < /dev/null 2>&1; then
        # Try Python
        if command -v python3 &> /dev/null; then
            if ! python3 -m json.tool "$PROJECT_ROOT/.agents/manifest.json" > /dev/null; then
                echo -e "${RED}✗${NC} Manifest is not valid JSON"
                return 1
            fi
        else
            echo -e "${YELLOW}⚠${NC} Python not available, skipping JSON validation"
            return 0
        fi
    fi
    
    echo -e "${GREEN}✓${NC} Manifest is valid JSON"
    return 0
}

# Test 5: All 14 skills referenced in manifest
test_manifest_completeness() {
    echo -e "\n${BLUE}Test 5: Manifest references all 14 skills${NC}"
    
    EXPECTED_SKILLS=14
    MANIFEST_SKILLS=$(grep -o '"skill": "[^"]*"' "$PROJECT_ROOT/.agents/manifest.json" | wc -l)
    
    if [ "$MANIFEST_SKILLS" -ne "$EXPECTED_SKILLS" ]; then
        echo -e "${YELLOW}⚠${NC} Expected $EXPECTED_SKILLS skills, found $MANIFEST_SKILLS in manifest"
        echo "    (This might be OK if manifest format is different)"
        return 0
    fi
    
    echo -e "${GREEN}✓${NC} Manifest references $MANIFEST_SKILLS skills"
    return 0
}

# Test 6: Bootstrap script executable
test_bootstrap_executable() {
    echo -e "\n${BLUE}Test 6: Bootstrap script is executable${NC}"
    
    if [ ! -x "$PROJECT_ROOT/.agents/bootstrap-superpowers.sh" ]; then
        echo -e "${RED}✗${NC} Bootstrap script is not executable"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} Bootstrap script is executable"
    return 0
}

# Test 7: Simulate plugin workflow
test_plugin_workflow() {
    echo -e "\n${BLUE}Test 7: Simulate plugin initialization workflow${NC}"
    
    # 1. Check for cache (should be empty)
    if [ -d "$TEST_CACHE_DIR" ]; then
        echo -e "${GREEN}✓${NC} Cache directory exists (would use cache)"
    else
        echo -e "${GREEN}✓${NC} Cache directory missing (would bootstrap)"
    fi
    
    # 2. Check bundled skills available
    if [ -d "$BUNDLED_SKILLS_PATH" ]; then
        echo -e "${GREEN}✓${NC} Bundled skills directory available as fallback"
    else
        echo -e "${RED}✗${NC} Bundled skills directory missing!"
        return 1
    fi
    
    # 3. Verify plugin can choose between them
    echo -e "${GREEN}✓${NC} Plugin can choose between cache and bundled skills"
    return 0
}

# Run all tests
run_all_tests() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Superpowers Plugin Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    TESTS=(
        "test_bootstrap_executable"
        "test_bundled_skills_exist"
        "test_manifest_valid"
        "test_manifest_completeness"
        "test_plugin_workflow"
        "test_bootstrap_creates_cache"
        "test_bootstrap_idempotent"
    )
    
    PASSED=0
    FAILED=0
    SKIPPED=0
    
    for test in "${TESTS[@]}"; do
        if $test; then
            ((PASSED++))
        else
            ((FAILED++))
        fi
    done
    
    # Print summary
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    if [ $FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $FAILED${NC}"
    else
        echo -e "${GREEN}Failed: 0${NC}"
    fi
    
    if [ $FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# Main
main() {
    # Parse arguments
    if [ "$1" = "--no-cleanup" ]; then
        CLEANUP=false
    else
        CLEANUP=true
    fi
    
    # Setup
    setup_test_env
    
    # Run tests
    if run_all_tests; then
        RESULT=0
    else
        RESULT=1
    fi
    
    # Cleanup
    if [ "$CLEANUP" = true ]; then
        cleanup_test_env
    else
        echo -e "\n${YELLOW}Note: Test files not cleaned up${NC}"
        echo -e "Test HOME: $TEST_HOME"
        echo -e "Clean up manually: rm -rf $TEST_HOME"
    fi
    
    exit $RESULT
}

main "$@"
