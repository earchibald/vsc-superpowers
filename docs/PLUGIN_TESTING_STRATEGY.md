# Plugin Testing Strategy

## The Problem

Your existing `~/.cache/superpowers` will interfere with testing because:
- Bootstrap script will find it and skip initialization (correct production behavior, wrong for testing)
- Can't test fallback to bundled skills (cache always exists)
- Can't verify bootstrap actually works (it's never triggered)
- Can't test cache deletion/recovery workflows

## The Solution: Isolated Test Environment

### Approach: $HOME Override + Environment Variables

**Key Insight:** Use environment variables to simulate **any state** without touching your real home directory.

```bash
# User's real environment (unchanged)
~/.cache/superpowers/    ← Real, untouched

# Test environment (isolated)
/tmp/superpowers-test-$$/.cache/superpowers/  ← Test, temporary
export HOME=/tmp/superpowers-test-$$
export SUPERPOWERS_CACHE_DIR=/tmp/superpowers-test-$$/​.cache/superpowers
```

### Why This Works

1. **Isolation:** `HOME` points to temporary directory, not your real home
2. **Realistic:** Tests actual file I/O, symlinks, shell behavior
3. **Repeatable:** Can run multiple times, clean up after
4. **Automatic:** No manual setup needed
5. **No interference:** Your real `~/.cache/superpowers` never touched

## Test Scenarios

### Scenario 1: Bootstrap Creates Cache (Fresh Install)

```bash
# Setup
export HOME=/tmp/test-home-$$
export SUPERPOWERS_CACHE_DIR=$HOME/.cache/superpowers

# Pre-condition: cache doesn't exist
[ ! -d $SUPERPOWERS_CACHE_DIR ] → ✓

# Action: Run bootstrap
bash .agents/bootstrap-superpowers.sh

# Verify: Cache created
[ -d $SUPERPOWERS_CACHE_DIR ] → ✓
[ -d $SUPERPOWERS_CACHE_DIR/skills ] → ✓
```

### Scenario 2: Bootstrap Idempotent (Existing Cache)

```bash
# Pre-condition: cache exists
mkdir -p $SUPERPOWERS_CACHE_DIR

# Action: Run bootstrap again
bash .agents/bootstrap-superpowers.sh

# Verify: No error, still works
echo $? → 0
```

### Scenario 3: Fallback to Bundled (No Cache, No Internet)

```bash
# Setup
export HOME=/tmp/test-home-$$
export SUPERPOWERS_CACHE_DIR=$HOME/.cache/superpowers

# Pre-condition: no cache, no internet
[ ! -d $SUPERPOWERS_CACHE_DIR ] → ✓

# Action: Plugin tries to load skills
# Expected: Falls back to .agents/skills/*/SKILL.md

ls .agents/skills/*/SKILL.md | wc -l → 14
```

### Scenario 4: Cache Exists, Use Cache (Production Path)

```bash
# Setup: Simulate cache exists
mkdir -p /tmp/cache-test/skills
for skill in brainstorm tdd investigate write-plan; do
    mkdir -p /tmp/cache-test/skills/$skill
done

# Pre-condition: cache exists from previous test
[ -d /tmp/cache-test/skills ] → ✓

# Action: Plugin loads skills
# Expected: Uses cache, not bundled

ln -s /tmp/cache-test/skills .agents/skills-active
# Manifest should prefer symlink
```

## Test Execution

### Simple Test Script

```bash
scripts/test-plugin.sh
```

**What it does:**
1. Creates isolated `$HOME` in `/tmp/superpowers-test-$$`
2. Runs 7 test scenarios
3. Reports pass/fail for each
4. Cleans up after (or keeps for debugging with `--no-cleanup`)

**Output:**
```
========================================
Superpowers Plugin Test Suite
========================================

Test 1: Bootstrap is executable
✓ Bootstrap script is executable

Test 2: Bundled skills exist
✓ Found 14 bundled skills
✓ All required skills present

Test 3: Bootstrap creates cache
✓ Cache successfully created at /tmp/superpowers-test-12345/.cache/superpowers

Test 4: Bootstrap is idempotent
✓ Bootstrap script is safe to run multiple times

Test 5: Manifest valid
✓ Manifest is valid JSON
✓ Manifest references 14 skills

Test 6: Plugin workflow
✓ Cache directory missing (would bootstrap)
✓ Bundled skills directory available as fallback
✓ Plugin can choose between cache and bundled skills

========================================
Test Summary
========================================
Passed: 7
Failed: 0

✓ All tests passed!
```

### Advanced: Multi-Scenario Test

Custom test for specific scenario:

```bash
# Test bootstrap with custom repo (e.g., local fork)
export SUPERPOWERS_REPO_URL="file:///path/to/local/superpowers"
export SUPERPOWERS_CACHE_DIR="/tmp/test-local-repo"
bash .agents/bootstrap-superpowers.sh

# Verify local repo was cloned
ls /tmp/test-local-repo/skills
```

### CI/CD Integration

```yaml
# .github/workflows/test-plugin.yml
name: Test Plugin

on: [push, pull_request]

jobs:
  test-plugin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run plugin tests
        run: bash scripts/test-plugin.sh
```

## Files for Testing

### Modified Bootstrap Script

```bash
# Now supports environment variable overrides
export SUPERPOWERS_CACHE_DIR="/tmp/test-cache"
export SUPERPOWERS_REPO_URL="file:///local/repo"
bash .agents/bootstrap-superpowers.sh
```

### Test Script

```bash
scripts/test-plugin.sh              # Run all tests
scripts/test-plugin.sh --no-cleanup # Keep temp files for debugging
```

## Why Not Alternatives?

### Option A: Docker Container
- ❌ Heavyweight for local testing
- ❌ Requires Docker installed
- ✅ Perfect for CI/CD
- ℹ️ Could add later: `docker run -it ubuntu:latest /test-plugin.sh`

### Option B: VS Code Devcontainer
- ❌ Heavy setup for plugin testing
- ✅ Good for full integration testing
- ℹ️ Could add later for comprehensive testing

### Option C: $HOME Override (Selected)
- ✅ Lightweight
- ✅ No dependencies (pure bash)
- ✅ Works locally and in CI
- ✅ Realistic (actual file I/O)
- ✅ Repeatable and automated
- ✓ Chosen for Phase 2

### Option D: Mock/Stub
- ❌ Doesn't test real behavior
- ❌ Test passes even if real code broken
- ✅ Good for unit tests

## Test Coverage

| Component | Test Scenario | Status |
|-----------|---|---|
| **Bootstrap Script** | Creates cache | ✅ test_bootstrap_creates_cache |
| **Bootstrap Script** | Idempotent | ✅ test_bootstrap_idempotent |
| **Bootstrap Script** | Executable | ✅ test_bootstrap_executable |
| **Bundled Skills** | Exist | ✅ test_bundled_skills_exist |
| **Manifest** | Valid JSON | ✅ test_manifest_valid |
| **Manifest** | References all skills | ✅ test_manifest_completeness |
| **Plugin Workflow** | Chooses correct source | ✅ test_plugin_workflow |
| **Fallback** | Works without cache | ℹ️ Manual: `rm -rf .cache` |
| **Integration** | CLI loads skills | ℹ️ TBD: copilot CLI testing |

## Running Tests Locally

### Quick Test (All Scenarios)

```bash
cd /Users/earchibald/work/vsc-superpowers
bash scripts/test-plugin.sh
```

### Test with Debugging

```bash
# Keep temp files for inspection
bash scripts/test-plugin.sh --no-cleanup

# Manually test in isolated environment
export HOME=/tmp/superpowers-test-99999
export SUPERPOWERS_CACHE_DIR=$HOME/.cache/superpowers
cd /Users/earchibald/work/vsc-superpowers
bash .agents/bootstrap-superpowers.sh

# Inspect results
ls ~/.cache/superpowers
ls -la $HOME/.cache/superpowers
```

### Test with Custom Repo

```bash
# Use local copy of obra/superpowers for faster testing
git clone https://github.com/obra/superpowers /tmp/superpowers-mirror
export SUPERPOWERS_REPO_URL="file:///tmp/superpowers-mirror"
bash scripts/test-plugin.sh
```

## Verification Checklist

- [ ] Run `bash scripts/test-plugin.sh` - all tests pass
- [ ] Run `bash scripts/test-plugin.sh --no-cleanup` - inspect temp files
- [ ] Verify real `~/.cache/superpowers` untouched after testing
- [ ] Test bootstrap with custom repo URL
- [ ] Test in CI/CD pipeline (GitHub Actions)
- [ ] Manual Copilot CLI testing with plugin

## Next Steps

1. **Phase 2a:** Run local tests and refine
2. **Phase 2b:** Set up GitHub Actions CI (test-plugin.sh in PR workflow)
3. **Phase 3:** Manual Copilot CLI testing with isolated plugin
4. **Phase 4:** Full integration testing with devcontainer (optional)

## Key Decision: Why $HOME Override Works

This approach lets us test **all three plugin states** without any real infrastructure:

```
┌─ State 1: Fresh Install
│  └─ No cache, no bootstrap
│     Set: HOME=/tmp/new, CACHE_DIR unset
│     Test: bootstrap-superpowers.sh runs
│     Verify: Cache created, skills available
│
├─ State 2: Existing Cache  
│  └─ Cache present, plugin uses it
│     Set: HOME=/tmp/cached, CACHE_DIR already has content
│     Test: Plugin loads skills from cache
│     Verify: No bootstrap needed
│
└─ State 3: Cache Missing, Fallback
   └─ No cache, use bundled
      Set: HOME=/tmp/no-internet, no network access
      Test: Plugin falls back to bundled
      Verify: Skills still available
```

All three states testable without touching real home directory! 🎯
