#!/usr/bin/env bash
set -e

################################################################################
# COPILOT CLI - SIMPLIFIED SEQUENTIAL TEST RUNNER
################################################################################

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS_DIR="${PROJECT_ROOT}/tmp/cli-test-results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$RESULTS_DIR"

# Cleanup
rm -f "${RESULTS_DIR}"/test-*.txt "$RESULTS_DIR"/*.md

# Test definitions (simplified)
TESTS=(
    "Planning:I want to add a user authentication system. Use planning skill - conduct interview naturally."
    "TDD:Implement password validation (min length, special chars, numbers). Use TDD: write test FIRST."
    "Investigation:Tests fail with 'TypeError: Cannot read property length of undefined'. Use investigation skill."
    "Loop:Continue with implementation (assume plan.md exists with unchecked items)"
    "Negative:What is the difference between a class and interface in TypeScript?"
    "Ambiguous:This isn't working."
    "CodeReview:Review this code: function processUser(user) { const name = user.name.toUpperCase(); return { id: user.id, name: name, email: user.email }; }"
)

echo "║════════════════════════════════════════════════════╗"
echo "║  Copilot CLI - 7-Test Inference Suite              ║"
echo "║════════════════════════════════════════════════════╝"
echo ""

cd "$PROJECT_ROOT"

# Clean environment
rm -f plan.md scratchpad.md docs/plans/*.md 2>/dev/null || true

# Run each test
PASSED=0
for i in {0..6}; do
    TEST_NUM=$((i + 1))
    IFS=':' read -r NAME PROMPT <<< "${TESTS[$i]}"
    
    OUTPUT_FILE="${RESULTS_DIR}/test-${TEST_NUM}-${NAME}.txt"
    
    echo "Test $TEST_NUM: $NAME"
    echo "─────────────────────────────────────────────────"
    
    # Run and capture
    if copilot -p "$PROMPT" --allow-all > "$OUTPUT_FILE" 2>&1; then
        LINES=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo "0")
        echo "✓ Completed ($LINES lines)"
        PASSED=$((PASSED + 1))
    else
        echo "✗ Failed"
    fi
    echo ""
done

echo "╔════════════════════════════════════════════════════╗"
echo "║  RESULTS: $PASSED/7 tests completed                    ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Output files:"
ls -1 "${RESULTS_DIR}"/test-*.txt | sed 's|^|  |'
echo ""
echo "Review outputs and score manually in GitHub issue #6"
