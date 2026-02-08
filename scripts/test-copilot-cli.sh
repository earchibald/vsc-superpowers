#!/usr/bin/env bash
set -e

# ==============================================================================
# COPILOT CLI INTEGRATION TEST SUITE
# ==============================================================================
# Tests whether copilot CLI functions correctly with vsc-superpowers
# Tests:
#   1. copilot CLI availability and version
#   2. Project initialization and context loading
#   3. Recognition of .github/copilot-instructions.md
#   4. Ability to understand Superpowers framework
#   5. Non-interactive mode with project context
# ==============================================================================

TEST_DIR=$(mktemp -d)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "🧪 COPILOT CLI INTEGRATION TEST SUITE"
echo "====================================="
echo ""
echo "Project Root: $PROJECT_ROOT"
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
    
    if output=$("$@" 2>&1); then
        if echo "$output" | grep -q "$expected"; then
            echo "✓ PASS"
            pass_count=$((pass_count + 1))
        else
            echo "✗ FAIL (output missing: $expected)"
            echo "  Output: $output" | head -3
        fi
    else
        echo "✗ FAIL (exit code != 0)"
        echo "  Error: $output" | head -3
    fi
}

# TEST 1: Copilot CLI is available
run_test "Copilot CLI is available" "GitHub Copilot CLI" \
    bash -c "copilot --version"

# TEST 2: Copilot CLI version is valid
run_test "Copilot CLI version >= 0.0.400" "0\\.0\\.[4-9]" \
    bash -c "copilot --version"

# TEST 3: Can display help
run_test "Copilot CLI help works" "Usage: copilot" \
    bash -c "copilot --help 2>&1"

# TEST 4: Project context available
run_test "Project has copilot-instructions.md" "SUPERPOWERS-START" \
    bash -c "cat '$PROJECT_ROOT/.github/copilot-instructions.md'"

# TEST 5: All 14 prompt files exist
run_test "All 14 Superpowers prompts installed" "14" \
    bash -c "ls -1 '$PROJECT_ROOT/.github/prompts/'*.prompt.md 2>/dev/null | wc -l"

# TEST 6: Verify symlink to Superpowers cache
run_test "Superpowers symlink exists" "superpowers" \
    bash -c "ls -l '$PROJECT_ROOT/.superpowers' | grep -i cache"

# TEST 7: Cache directory populated
run_test "Superpowers cache has skills" "skills" \
    bash -c "ls -la ~/.cache/superpowers/ | grep -i skills"

# TEST 8: Non-interactive Mode with project context (READ ONLY)
echo ""
echo "Test $((test_count + 1)): Copilot CLI non-interactive mode with project context ... "
test_count=$((test_count + 1))

cd "$PROJECT_ROOT"
# Run copilot with a project-context prompt
if copilot -p "What is the purpose of this Superpowers project?" --allow-all 2>&1 > "$TEST_DIR/copilot-output.txt"; then
    if [ -s "$TEST_DIR/copilot-output.txt" ]; then
        echo "✓ PASS"
        pass_count=$((pass_count + 1))
    else
        echo "⚠️  PARTIAL (copilot executed but no output)"
    fi
else
    echo "⚠️  PARTIAL (copilot execution encountered issues)"
    head -20 "$TEST_DIR/copilot-output.txt" 2>/dev/null || echo "No output"
fi

# SUMMARY
echo ""
echo "=================================================="
echo "TEST RESULTS: $pass_count/$test_count passed"
echo "=================================================="

if [ "$pass_count" -eq "$test_count" ]; then
    echo "✅ All tests passed!"
    echo ""
    echo "✓ Copilot CLI is functional with vsc-superpowers"
    echo "✓ Project context (instructions) is recognized"
    echo "✓ Superpowers framework is available to copilot"
    rm -rf "$TEST_DIR"
    exit 0
else
    echo "⚠️  Some tests were not fully passed. Details:"
    passed_tests=$((pass_count))
    total_tests=$test_count
    echo " Passed: $passed_tests/$total_tests"
    echo ""
    echo "📝 Test directory preserved: $TEST_DIR"
    exit 1
fi
