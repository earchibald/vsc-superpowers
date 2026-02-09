# Testing Copilot CLI Hooks

This document explains how to test the Copilot CLI hooks system that enforces the Iron Law of Verification.

## Overview

The hooks system has 4 comprehensive test suites:

1. **Session Start Hook** - Bootstrap and cache management (8 tests)
2. **Pre-Command Hook** - Iron Law enforcement (11 tests)
3. **Verification Markers** - Marker lifecycle and validation (8 tests)
4. **Integration** - End-to-end verification library (8 tests)

**Total:** 35 tests, 34 passing (97.1%)

## Running Tests

### Run All Tests

```bash
tests/hooks/run-all-tests.sh
```

**Expected output:** 3/4 suites passing (session-start has 1 test with variable scope issue)

### Run Individual Suites

```bash
# Session start (bootstrap hook)
tests/hooks/session-start.test.sh

# Pre-command (Iron Law guard)
tests/hooks/pre-command.test.sh

# Verification markers (marker lifecycle)
tests/hooks/verification-marker.test.sh

# Integration (library integration)
tests/hooks/integration.test.sh

# Hooks.json validation
tests/hooks/hooks-json.test.sh
```

## Test Suite Details

### Suite 1: Session Start Hook (8 tests)

Tests the `sessionStart` hook that bootstraps Superpowers cache.

**What it tests:**
- Hook script exists and is executable
- Bootstrap creates cache when missing
- Update pulls latest when cache exists
- Success banner displays "Superpowers Active"
- Hook exits with code 0 (non-blocking)
- Idempotency (multiple runs safe)
- Network failure handling (graceful exit)

**Known issue:** Git pull verification test has variable scope issue (test implementation, not script)

**Run:** `tests/hooks/session-start.test.sh`

### Suite 2: Pre-Command Hook (11 tests, 100% passing) ✅

Tests the `preToolUse` hook that enforces Iron Law before dangerous commands.

**What it tests:**
- Hook script exists and is executable
- JSON parsing from Copilot CLI stdin
- Malformed JSON handling (graceful failures)
- Git commit detection and warning
- Git push detection and warning
- Read-only commands (git log) ignored
- Missing verification marker triggers warning
- Recent marker (<1 hour) allows commit silently
- Stale marker (>1 hour) triggers warning
- Hook always exits 0 (non-blocking)
- Empty command handling

**Run:** `tests/hooks/pre-command.test.sh`

### Suite 3: Verification Markers (8 tests, 100% passing) ✅

Tests the verification marker lifecycle and validation.

**What it tests:**
- Marker file creation
- Timestamp format validation
- Recent marker detection (<1 hour)
- Stale marker detection (>1 hour)
- Missing marker detection
- Project hash consistency
- Cross-workspace isolation (different paths = different hashes)
- Marker cleanup

**Run:** `tests/hooks/verification-marker.test.sh`

### Suite 4: Integration (8 tests, 100% passing) ✅

Tests the verification library integration with test runners.

**What it tests:**
- Verification library can be sourced
- `create_verification_marker()` function works
- Marker contains valid timestamp
- `remove_verification_marker()` function works
- `check_verification_status()` function works
- Master test runner sources library
- Master test runner creates marker on success
- Master test runner removes marker on failure

**Run:** `tests/hooks/integration.test.sh`

## Manual Testing with Copilot CLI

### Prerequisites

1. Install Copilot CLI: `npm install -g @githubnext/github-copilot-cli`
2. Authenticate: `copilot auth`
3. Ensure `hooks/hooks.json` exists

### Test Session Start Hook

```bash
# Plugin install required first:
copilot plugin install $(pwd)

# Clear cache to test bootstrap
rm -rf ~/.cache/superpowers

# Start copilot session
copilot

# Expected output:
# 🦸 Superpowers Active
# (or bootstrap message if cache was missing)

# Verify cache was created
ls -la ~/.cache/superpowers
```

### Test Pre-Command Hook (Iron Law Enforcement)

```bash
# Clear verification marker
rm -f /tmp/.superpowers-verified-*

# Make a code change
echo "// test" >> some-file.js

# Try to commit via copilot
copilot "commit this change"

# Expected warning:
# ⚠️  Warning: No verification marker found
# ⚠️  Run tests before committing (Iron Law of Verification)

# Run tests to create marker
tests/hooks/run-all-tests.sh

# Expected output:
# ✅ All tests passed!
# ✅ Verification marker created: /tmp/.superpowers-verified-...

# Try commit again
copilot "commit this change"

# Expected: No warning (marker exists and is recent)
```

### Test Marker Expiration

```bash
# Create marker
tests/hooks/run-all-tests.sh

# Backdate marker by 2 hours
PROJECT_HASH=$(echo -n "$(pwd)" | md5sum | cut -d' ' -f1)
MARKER="/tmp/.superpowers-verified-${PROJECT_HASH}"
echo $(($(date +%s) - 7200)) > "$MARKER"

# Try to commit
copilot "commit this change"

# Expected warning:
# ⚠️  Warning: Verification marker is stale (2 hours old)
# ⚠️  Run tests before committing
```

## Test Framework

The hooks use a custom bash testing framework with:

**Assertion Helpers:**
- `assert_equals(expected, actual, message)` - Compare values
- `assert_contains(haystack, needle, message)` - Substring match
- `assert_file_exists(path, message)` - File existence check
- `assert_file_not_exists(path, message)` - File absence check

**Test Structure:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_something() {
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ condition ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} Test description"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} Test description"
    fi
}

# Summary
if [ $TESTS_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
```

## Debugging Failed Tests

### Enable Verbose Output

```bash
# Run with bash debug mode
bash -x tests/hooks/pre-command.test.sh

# Or add to test script
set -x  # Enable command tracing
```

### Check Hook Output

```bash
# Test hook manually
echo '{"timestamp":"2026-02-08T12:00:00Z","cwd":"/tmp/test","toolName":"bash","toolArgs":"{\"command\":\"git commit -m test\"}"}' | hooks/scripts/pre-command.sh
```

### Inspect Verification Markers

```bash
# List all markers
ls -la /tmp/.superpowers-verified-*

# Check marker content
cat /tmp/.superpowers-verified-<hash>

# Calculate project hash
echo -n "$(pwd)" | md5sum | cut -d' ' -f1
```

### Common Issues

**1. Syntax errors in bash:**
```bash
# Check syntax without running
bash -n hooks/scripts/pre-command.sh
```

**2. JSON parsing failures:**
```bash
# Test with jq
echo '<json>' | jq '.toolArgs | fromjson | .command'

# Test without jq (fallback)
echo '<json>' | grep -o '"toolArgs":"[^"]*"' | sed 's/toolArgs://g'
```

**3. Marker not found:**
```bash
# Verify project hash calculation matches
PROJECT_HASH=$(echo -n "$(pwd)" | md5sum | cut -d' ' -f1)
echo "Expected marker: /tmp/.superpowers-verified-${PROJECT_HASH}"

# Check if marker exists with different hash
ls -la /tmp/.superpowers-verified-*
```

## Contributing Tests

When adding new hook functionality:

1. **Write failing tests first** (TDD)
2. **Test all edge cases:**
   - Valid input
   - Invalid input
   - Missing input
   - Network failures (for external calls)
3. **Ensure non-blocking behavior:** Hooks should always exit 0
4. **Update test suites:** Add new tests to appropriate suite files
5. **Update master runner:** Add new suite to `run-all-tests.sh`

## Test Coverage

Current coverage by component:

| Component | Tests | Passing | Coverage |
|-----------|-------|---------|----------|
| hooks.json | 6 | 6 | 100% ✅ |
| session-start.sh | 8 | 7 | 87.5% ⚠️ |
| pre-command.sh | 11 | 11 | 100% ✅ |
| verification-lib.sh | 8 | 8 | 100% ✅ |
| Integration | 8 | 8 | 100% ✅ |
| **Total** | **35** | **34** | **97.1%** |

## CI/CD Integration

To run hook tests in CI:

```yaml
# .github/workflows/test-hooks.yml
name: Test Hooks
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run hook tests
        run: tests/hooks/run-all-tests.sh
```

## Further Reading

- [README.md - Copilot CLI Hooks section](../README.md#copilot-cli-hooks-iron-law-enforcement)
- [CHEATSHEET.md - Verification workflows](./CHEATSHEET.md)
- [Plan document](./plans/2026-02-08-copilot-cli-hooks.md)
