#!/usr/bin/env bash
set -e

################################################################################
# COPILOT CLI - MANUAL SINGLE TEST RUNNER
################################################################################
# Run individual tests for manual inspection
# Helps diagnose hanging or slow-running tests

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS_DIR="${PROJECT_ROOT}/tmp/cli-test-results"
TEST_NUM=${1:-1}

mkdir -p "$RESULTS_DIR"

# Test definitions
declare -A TESTS=(
    [1]="Planning Behavior"
    [2]="TDD Behavior"
    [3]="Investigation Behavior"
    [4]="Loop of Autonomy"
    [5]="Negative Case"
    [6]="Ambiguous Context"
    [7]="Code Review"
)

declare -A PROMPTS=(
    [1]="I want to add a user authentication system to this project. It should support login, logout, and session management. Use the planning skill from Superpowers framework: conduct an interview naturally."
    
    [2]="Let's implement a password validation function checking for minimum length, special characters, and numbers. Use TDD: write a failing test FIRST, then implement to pass it."
    
    [3]="The tests are failing with 'TypeError: Cannot read property length of undefined'. Use the investigation skill: ask for output, gather evidence, create scratchpad.md with theories."
    
    [4]="Continue with the implementation. (Assume plan.md exists with unchecked items)"
    
    [5]="What is the difference between a class and an interface in TypeScript?"
    
    [6]="This isn't working."
    
    [7]="Review this code: function processUser(user) { const name = user.name.toUpperCase(); return { id: user.id, name: name, email: user.email }; }"
)

echo "═══════════════════════════════════════════════════════"
echo "Test $TEST_NUM: ${TESTS[$TEST_NUM]}"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Prompt:"
echo "${PROMPTS[$TEST_NUM]}"
echo ""
echo "Running copilot CLI..."
echo ""

output_file="${RESULTS_DIR}/test-${TEST_NUM}-output.txt"

# Run with output visible
copilot -p "${PROMPTS[$TEST_NUM]}" --allow-all 2>&1 | tee "$output_file"

echo ""
echo "Output saved to: $output_file"
echo "Lines: $(wc -l < "$output_file")"
