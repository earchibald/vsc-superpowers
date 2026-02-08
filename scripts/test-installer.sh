#!/usr/bin/env bash
set -e

# ==============================================================================
# INSTALLER INTEGRATION TEST SUITE
# ==============================================================================
# Tests: Preview, confirmation, symlink creation, idempotency, backup behavior
# ==============================================================================

TEST_DIR=$(mktemp -d)
INSTALLER_PATH="$(cd "$(dirname "$0")/.." && pwd)/install-superpowers.sh"

echo "🧪 SUPERPOWERS INSTALLER - INTEGRATION TEST SUITE"
echo "=================================================="
echo ""
echo "Test Directory: $TEST_DIR"
echo ""

test_count=0
pass_count=0

run_test() {
    local name="$1"
    local expected="$2"
    shift 2
    
    test_count=$((test_count + 1))
    echo -n "Test $test_count: $name ... "
    
    mkdir -p "$TEST_DIR/test_$test_count"
    cd "$TEST_DIR/test_$test_count" || exit 1
    
    if output=$("$@" 2>&1); then
        if echo "$output" | grep -q "$expected"; then
            echo "✓ PASS"
            pass_count=$((pass_count + 1))
        else
            echo "✗ FAIL (output missing: $expected)"
            echo "Output: $output"
        fi
    else
        echo "✗ FAIL (exit code != 0)"
    fi
}

# TEST 1: Preview - Declined installation
run_test "Preview shown, installation declined" "cancelled" \
    bash -c "echo n | bash \"$INSTALLER_PATH\" 2>&1"

# TEST 2: Fresh installation - Create symlink
run_test "First install creates symlink" "Symlink created" \
    bash -c "echo y | bash \"$INSTALLER_PATH\" 2>&1"

# TEST 3: Verify symlink exists and is correct
run_test "Symlink resolves to cache" "/Users/earchibald/.cache/superpowers" \
    bash -c "readlink .superpowers"

# TEST 4: Instructions file created
run_test "Instructions file created" "SUPERPOWERS-START" \
    bash -c "cat ./.github/copilot-instructions.md"

# TEST 5: No absolute paths in instructions
run_test "No absolute ~/.cache paths in instructions" "No absolute" \
    bash -c "grep '~/.cache/superpowers' .github/copilot-instructions.md && echo 'FOUND' || echo 'No absolute'"

# TEST 6: Idempotency - Second run
run_test "Second run skips existing symlink" "already correct" \
    bash -c "echo y | bash \"$INSTALLER_PATH\" 2>&1"

# TEST 7: Directory backup
run_test "Existing directory backed up to .old" "Backing up" \
    bash -c "mkdir -p .superpowers && echo 'test' > .superpowers/file.txt && echo y | bash \"$INSTALLER_PATH\" 2>&1"

# TEST 8: Backup directory contains old files  
run_test "Backup directory preserved old files" "test" \
    bash -c "cat .superpowers.old/file.txt"

# TEST 9: All 14 skills installed
run_test "Skills prompts directory created" "14 prompts" \
    bash -c "ls .github/prompts/*.prompt.md 2>/dev/null | wc -l | xargs -I {} echo '{} prompts'"

# TEST 10: Skills accessible via symlink
run_test "Skill files accessible through symlink" "brainstorming\|writing-plans" \
    bash -c "ls -1 .superpowers/skills/ | head -5"

# SUMMARY
echo ""
echo "=================================================="
echo "TEST RESULTS: $pass_count/$test_count passed"
echo "=================================================="

if [ "$pass_count" -eq "$test_count" ]; then
    echo "✅ All tests passed!"
    rm -rf "$TEST_DIR"
    exit 0
else
    echo "❌ Some tests failed. Test directory preserved: $TEST_DIR"
    exit 1
fi
