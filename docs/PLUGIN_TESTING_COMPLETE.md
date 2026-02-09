# Plugin Testing: Isolation & Automation Strategy

## Challenge Solved

**Problem:** Real `~/.cache/superpowers` prevents testing bootstrap behavior.

**Solution:** Automated test suite with `$HOME` override + environment variables creates isolated test environment.

## How It Works

### 1. Isolated Environment (`$HOME` Override + Workspace-Local Temp)

```bash
# Create temp home directory for testing (workspace-local)
PROJECT_ROOT=$(git rev-parse --show-toplevel)
TEST_HOME="${PROJECT_ROOT}/tmp/superpowers-test-$$"
mkdir -p "$TEST_HOME"

# Override user's home
export HOME="$TEST_HOME"
export SUPERPOWERS_CACHE_DIR="$TEST_HOME/.cache/superpowers"

# Now all file operations stay in temp directory
cd /Users/earchibald/work/vsc-superpowers
bash .agents/bootstrap-superpowers.sh

# Real ~/.cache/superpowers: UNTOUCHED ✓
# Test cache: ./tmp/superpowers-test-$$/.cache/superpowers (git ignored)
```

### 2. Test Script (`scripts/test-plugin.sh`)

Fully automated test suite that:

```bash
1. Setup: Create isolated HOME, verify isolation
2. Test: Run 7 test scenarios
   - Bootstrap creates cache ✓
   - Bootstrap is idempotent ✓
   - Bundled skills exist ✓
   - Manifest valid JSON ✓
   - Manifest complete ✓
   - Bootstrap executable ✓
   - Plugin workflow logic ✓
3. Report: Pass/fail summary
4. Cleanup: Remove temp files (or keep with --no-cleanup)
```

### 3. Environment Variable Overrides

Bootstrap script now supports testing:

```bash
# Production (normal use)
~/.cache/superpowers available automatically

# Testing (isolated, workspace-local)
export SUPERPOWERS_CACHE_DIR="${PROJECT_ROOT}/tmp/test-cache"
export SUPERPOWERS_REPO_URL="file:///local/repo"
bash .agents/bootstrap-superpowers.sh
```

## Running Tests

### Quick Start

```bash
# Run all tests (automatic cleanup)
bash scripts/test-plugin.sh

# Output: ✓ All tests passed!
```

### With Debugging

```bash
# Keep temp files for manual inspection
bash scripts/test-plugin.sh --no-cleanup

# Manually test in the isolated environment
export HOME="${PROJECT_ROOT}/tmp/superpowers-test-<id>"
cd .agents
./bootstrap-superpowers.sh
# Inspect: ls -la ~/.cache/superpowers
```

### With Custom Repo

```bash
# Test with local copy of obra/superpowers (workspace-local, faster)
git clone https://github.com/obra/superpowers "${PROJECT_ROOT}/tmp/superpowers-mirror"
export SUPERPOWERS_REPO_URL="file://${PROJECT_ROOT}/tmp/superpowers-mirror"
bash scripts/test-plugin.sh
```

## Test Results (Live Run)

```
Setting up isolated test environment...
✓ Isolated HOME: ./tmp/superpowers-test-84423
✓ Test CACHE_DIR: ./tmp/superpowers-test-84423/.cache/superpowers

Test 1: Bootstrap creates cache
✓ Cache successfully created at ./tmp/superpowers-test-84423/.cache/superpowers

Test 2: Bootstrap is idempotent
✓ Bootstrap script is safe to run multiple times

Test 3: Bundled skills exist
✓ Found 14 bundled skills
✓ All required skills present

Test 4: Manifest is valid JSON
✓ Manifest is valid JSON

Test 5: Manifest references all 14 skills
✓ Manifest references 14 skills

Test 6: Bootstrap script is executable
✓ Bootstrap script is executable

Test 7: Plugin initialization workflow
✓ Cache directory missing (would bootstrap)
✓ Bundled skills directory available as fallback
✓ Plugin can choose between cache and bundled skills

========================================
Passed: 7 | Failed: 0
✓ All tests passed!
```

## Test Coverage

### ✅ Tested (Automated)

- Bootstrap script creates cache from upstream repo
- Bootstrap handles existing cache gracefully (idempotent)
- All 14 bundled skills present
- Manifest is valid JSON with all skills referenced
- Plugin can switch between cache and bundled
- Bootstrap script is executable
- Environment variable overrides work

### ✅ Ready to Test (Manual - Later)

- Copilot CLI loads plugin correctly
- Plugin auto-discovers skills
- Skills load based on natural language query
- Cache symlink works in practice
- Fallback to bundled works without cache
- Multi-project cache sharing works
- CI/CD integration

### Integration Testing (Phase 3)

```bash
# Manual CLI testing (requires Copilot CLI v0.0.402+)
copilot plugin add file:///path/to/vsc-superpowers
copilot "help me debug this"
# Verify skills are offered contextually
```

## Architecture Benefits

This strategy enables:

1. **No Interference** - Your real `~/.cache/superpowers` never touched
2. **Repeatable** - Run tests anytime, same results
3. **Automated** - No manual setup, CI-ready
4. **Realistic** - Tests actual file I/O and shell behavior
5. **Debuggable** - Keep temp files with `--no-cleanup` to inspect
6. **Fast** - Tests complete in seconds
7. **Scalable** - Easy to add new test scenarios

## CI/CD Integration (Ready)

```yaml
# .github/workflows/test-plugin.yml
name: Test Plugin
on: [push, pull_request]
jobs:
  test-plugin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Test plugin bootstrap
        run: bash scripts/test-plugin.sh
```

Just drop this in `.github/workflows/` and every PR/commit runs full plugin tests!

## Why This Approach?

| Approach | Isolation | Realistic | Automated | Local | CI/CD |
|----------|-----------|-----------|-----------|-------|-------|
| $HOME override | ✅ | ✅ | ✅ | ✅ | ✅ |
| Docker container | ✅ | ✅ | ✅ | ⚠️ | ✅ |
| VS Code devcontainer | ✅ | ✅ | ⚠️ | ✅ | ⚠️ |
| Mock/stub | ⚠️ | ❌ | ✅ | ✅ | ✅ |

**$HOME override:** Perfect balance of simplicity, realism, and automation.

## Files Included

```
scripts/test-plugin.sh                    # Test suite (7 tests)
.agents/bootstrap-superpowers.sh          # Updated with env var support
docs/PLUGIN_TESTING_STRATEGY.md          # This comprehensive guide
```

## Key Files for Future Testing

### Environment Variables Supported

```bash
# Override cache location (for testing)
SUPERPOWERS_CACHE_DIR="/custom/path"

# Override upstream repo (for testing)
SUPERPOWERS_REPO_URL="file:///local/repo"

# Combined (full test override)
export HOME="/tmp/test-$$"
export SUPERPOWERS_CACHE_DIR="$HOME/.cache/superpowers"
export SUPERPOWERS_REPO_URL="file:///tmp/superpowers-local"
bash .agents/bootstrap-superpowers.sh
```

## Next: Manual Integration Testing

Once local automated tests pass, test with actual Copilot CLI:

```bash
# 1. Install plugin from feature branch
copilot plugin add file:///path/to/vsc-superpowers

# 2. Test interactive mode
copilot
> use TDD to implement this feature
# Verify: Copilot suggests TDD skill

# 3. Test programmatic mode
copilot -p "I need to debug a test failure"
# Verify: Copilot suggests investigate + systematic debugging

# 4. Verify cache integration
echo "Testing cache..."
ls ~/.cache/superpowers/skills
# Should show skills from obra/superpowers, not bundled
```

## Summary

✅ **What's Tested:** Bootstrap script, bundled skills, manifest, environment overrides  
✅ **How:** Isolated $HOME + env vars, no interference with real system  
✅ **When:** Run anytime: `bash scripts/test-plugin.sh`  
✅ **Why:** Realistic testing without dependencies or external services  
✅ **Next:** Manual CLI integration testing (Phase 3)  

The plugin infrastructure is **fully testable without touching your real home directory**! 🎉
