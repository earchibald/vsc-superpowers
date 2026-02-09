# Copilot CLI Hooks Implementation Plan

**Date:** 2026-02-08  
**Feature Branch:** `feature/copilot-cli-hooks`  
**Development Approach:** Test-Driven Development (TDD)

---

## Overview

Implement GitHub Copilot CLI Hooks system to achieve parity with obra/superpowers (Claude Code). This allows programmatic enforcement of the "Loop of Autonomy" and "Iron Law of Verification" rather than relying solely on prompt inference.

## Goals

1. **Programmatic Safety**: Enforce Superpowers patterns via CLI hooks
2. **Bootstrap Automation**: Auto-detect and bootstrap Superpowers cache
3. **Context Injection**: Inject framework awareness at session start
4. **Verification Guards**: Warn when Iron Law violations detected (pre-command)

## Architecture

### Hook Mapping

| Superpowers Concept | Claude Code Hook | Copilot CLI Hook | Implementation |
|---------------------|------------------|------------------|----------------|
| Bootloader | SessionStart | `sessionStart` | `hooks/session-start.sh` |
| Safety Guard | PreToolUse | `preToolUse` | `hooks/pre-command.sh` |
| Context Injection | UserPrompt | `userPromptSubmitted` | (Handled via instructions.md) |

### Data Flow

```
1. User runs `copilot` in terminal
2. Copilot CLI detects `.github/hooks/hooks.json`
3. sessionStart fires:
   - Executes `session-start.sh`
   - Checks for `~/.cache/superpowers`
   - Bootstraps if missing (clones upstream)
   - Prints "🦸 Superpowers Active" to terminal
4. User asks to "commit changes"
5. preToolUse fires (matching bash tool):
   - Executes `pre-command.sh`
   - Analyzes command (e.g., `git commit`)
   - Checks if verification was run recently
   - Warns if violating Iron Law
```

### Hook Payload Structure

Copilot CLI sends JSON to stdin:
```json
{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"git commit -m 'feat: ...'\"}"
}
```

Scripts exit 0 to allow execution, non-zero to block (if supported), or print warnings to stderr.

---

## Implementation Steps (TDD Approach)

### Phase 1: Hook Infrastructure & Testing Framework

- [ ] **Step 1.1**: Create test infrastructure for hook scripts
  - Write tests for `session-start.sh` behavior
  - Write tests for `pre-command.sh` behavior
  - Set up fixture directories for testing
  - Mock Copilot CLI JSON payloads
  - **Test File**: `tests/hooks/session-start.test.sh`
  - **Test File**: `tests/hooks/pre-command.test.sh`

- [ ] **Step 1.2**: Create hooks directory structure
  - Create `.github/hooks/` directory
  - Create `.github/hooks/scripts/` directory
  - **Verify**: Directories exist

- [ ] **Step 1.3**: Write failing test for `hooks.json` manifest
  - Test validates JSON structure
  - Test checks hook registration (sessionStart, preToolUse)
  - **Test File**: `tests/hooks/hooks-json.test.sh`

- [ ] **Step 1.4**: Implement `hooks.json` to pass tests
  - Register sessionStart hook → `scripts/session-start.sh`
  - Register preToolUse hook → `scripts/pre-command.sh`
  - **Implementation**: `.github/hooks/hooks.json`

### Phase 2: Session Start Hook (Bootstrap)

- [ ] **Step 2.1**: Write failing test for session-start.sh
  - Test checks for `~/.cache/superpowers` existence
  - Test verifies bootstrap when cache missing
  - Test validates "🦸 Superpowers Active" output
  - Test ensures idempotency (safe to run multiple times)
  - **Test File**: `tests/hooks/session-start.test.sh` (expand)

- [ ] **Step 2.2**: Implement session-start.sh to pass tests
  - Check for `~/.cache/superpowers`
  - Clone obra/superpowers if missing
  - Print success banner
  - Exit 0 (allow session to continue)
  - **Implementation**: `.github/hooks/scripts/session-start.sh`

- [ ] **Step 2.3**: Write test for cache update logic
  - Test validates `git pull` when cache exists
  - Test handles network failures gracefully
  - **Test File**: `tests/hooks/session-start.test.sh` (expand)

- [ ] **Step 2.4**: Implement cache update logic
  - `cd ~/.cache/superpowers && git pull` when cache exists
  - Fail silently on network errors (don't block session)
  - **Implementation**: Update `session-start.sh`

### Phase 3: Pre-Command Hook (Iron Law Guard)

- [ ] **Step 3.1**: Write failing test for pre-command.sh JSON parsing
  - Test parses Copilot CLI JSON payload from stdin
  - Test extracts `toolName`, `toolArgs`, `cwd`
  - Test handles malformed JSON gracefully
  - **Test File**: `tests/hooks/pre-command.test.sh` (expand)

- [ ] **Step 3.2**: Implement JSON parsing in pre-command.sh
  - Read JSON from stdin
  - Parse with `jq` or fallback to grep/sed
  - Extract command for analysis
  - **Implementation**: `.github/hooks/scripts/pre-command.sh`

- [ ] **Step 3.3**: Write failing test for commit detection
  - Test detects `git commit` commands
  - Test detects `git push` commands
  - Test ignores read-only commands (git log, git status)
  - **Test File**: `tests/hooks/pre-command.test.sh` (expand)

- [ ] **Step 3.4**: Implement commit detection logic
  - Pattern match against `git commit`, `git push`
  - Allow read-only operations
  - **Implementation**: Update `pre-command.sh`

- [ ] **Step 3.5**: Write failing test for verification checks
  - Test checks for recent test runs (temp file marker)
  - Test warns if tests not run before commit
  - Test allows commit if verification passed recently
  - **Test File**: `tests/hooks/pre-command.test.sh` (expand)

- [ ] **Step 3.6**: Implement Iron Law verification check
  - Check for `/tmp/.superpowers-verified-${PROJECT_HASH}` marker
  - Warn to stderr if marker missing/stale
  - Exit 0 (warn but don't block - educate, don't frustrate)
  - **Implementation**: Update `pre-command.sh`

### Phase 4: Verification Marker Integration

- [ ] **Step 4.1**: Write failing test for verification marker creation
  - Test validates marker file created after test run
  - Test includes timestamp in marker
  - Test validates marker cleanup on test failure
  - **Test File**: `tests/hooks/verification-marker.test.sh`

- [ ] **Step 4.2**: Implement verification marker in test runners
  - Update `scripts/test-cli-inference.sh` to create marker on success
  - Update `/tdd` skill to create marker after test pass
  - Include project path hash in marker name (for multi-workspace support)
  - **Implementation**: Update test scripts

- [ ] **Step 4.3**: Write test for marker expiration
  - Test validates markers older than 1 hour are ignored
  - Test checks modification time of marker file
  - **Test File**: `tests/hooks/verification-marker.test.sh` (expand)

- [ ] **Step 4.4**: Implement marker expiration logic
  - Check marker file mtime
  - Warn if marker older than 3600 seconds (1 hour)
  - **Implementation**: Update `pre-command.sh`

### Phase 5: Installer Integration

- [ ] **Step 5.1**: Write failing test for installer hook setup
  - Test validates installer creates `.github/hooks/` directory
  - Test validates hooks.json is created
  - Test validates hook scripts are executable
  - **Test File**: `tests/installer/hooks-setup.test.sh`

- [ ] **Step 5.2**: Update install-superpowers.sh for hooks
  - Create `.github/hooks/` directory
  - Copy `hooks.json` to `.github/hooks/hooks.json`
  - Copy hook scripts to `.github/hooks/scripts/`
  - Set executable permissions on scripts
  - **Implementation**: Update `install-superpowers.sh`

- [ ] **Step 5.3**: Write test for upgrade scenario
  - Test validates hooks are updated when re-running installer
  - Test preserves user customizations (if any)
  - **Test File**: `tests/installer/hooks-upgrade.test.sh`

- [ ] **Step 5.4**: Implement upgrade logic in installer
  - Backup existing hooks to `.github/hooks.old/`
  - Install new hooks
  - Log upgrade actions
  - **Implementation**: Update `install-superpowers.sh`

### Phase 6: Documentation & Verification

- [ ] **Step 6.1**: Write documentation for hooks system
  - Explain hook architecture in README.md
  - Document Iron Law enforcement behavior
  - Provide troubleshooting guide
  - **Documentation**: Update `README.md`

- [ ] **Step 6.2**: Create hook testing guide
  - Document how to test hooks locally
  - Provide example JSON payloads for manual testing
  - **Documentation**: Create `docs/TESTING_HOOKS.md`

- [ ] **Step 6.3**: Update CHEATSHEET.md
  - Add "Loop of Autonomy (Automated)" section
  - Explain programmatic enforcement
  - **Documentation**: Update `docs/CHEATSHEET.md`

- [ ] **Step 6.4**: Run full test suite
  - Execute all hook tests
  - Verify installer tests pass
  - Run inference tests to ensure no regression
  - **Verification**: `./scripts/test-hooks.sh` (to be created)

- [ ] **Step 6.5**: Manual verification with copilot CLI
  - Install Superpowers in test workspace
  - Run `copilot` and verify "🦸 Superpowers Active"
  - Attempt commit without tests, verify warning
  - Run tests, commit, verify no warning
  - **Manual Testing**: Document results

---

## Success Criteria

✅ **Hook Infrastructure**
- `.github/hooks/hooks.json` exists and is valid
- `session-start.sh` and `pre-command.sh` are executable
- All tests pass (100% coverage for critical paths)

✅ **Bootstrap Behavior**
- Session start auto-bootstraps `~/.cache/superpowers` if missing
- User sees "🦸 Superpowers Active" banner
- Bootstrap is idempotent (safe to run multiple times)

✅ **Iron Law Enforcement**
- Pre-command hook detects `git commit` and `git push`
- Warns (stderr) if verification marker missing/stale
- Does NOT block operations (educate, don't frustrate)
- Marker created after successful test runs

✅ **Installer Integration**
- `install-superpowers.sh` sets up hooks automatically
- Upgrade scenario preserves functionality
- Hooks work immediately after install

✅ **Documentation**
- Architecture explained in README
- Testing guide for hooks available
- Troubleshooting section covers common issues

---

## Technical Decisions

### Why bash for hooks?
- Copilot CLI hooks must be cross-platform shell scripts
- Bash is available on macOS/Linux (primary targets)
- Minimal dependencies (use `jq` if available, fallback otherwise)

### Why warn instead of block?
- Enforcement should educate, not frustrate
- Users may have valid reasons to skip tests temporarily
- stderr warnings visible but non-blocking

### Why temp markers for verification?
- Lightweight (no database needed)
- Cross-session persistence
- Easy to inspect/debug (`ls /tmp/.superpowers-*`)
- Auto-cleanup via OS tmpdir policies

### Why 1-hour marker expiration?
- Balance between safety and convenience
- Long enough for typical TDD workflow
- Short enough to catch stale verification

---

## Testing Strategy

### Unit Tests (Bash)
- Each hook script has corresponding `.test.sh`
- Tests use fixtures and mocked JSON payloads
- Assert on exit codes, stdout, stderr

### Integration Tests
- Full installer → hooks setup flow
- Copilot CLI mock integration (if feasible)
- Multi-workspace marker isolation

### Manual Verification
- Real copilot CLI usage with hooks enabled
- Verification marker creation/consumption cycle
- Network failure scenarios (bootstrap)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Copilot CLI hook API changes | High | Monitor GitHub Copilot CLI release notes, version detection |
| `jq` not installed on user system | Medium | Fallback to grep/sed for JSON parsing, use `command -v jq` |
| Hook execution errors break CLI | High | All hooks exit 0, errors logged to stderr only |
| Marker cleanup on shared machines | Low | Use project path hash in marker name, 1-hour expiration |
| Bootstrap network failures | Medium | Graceful failure, suggest manual clone, don't block session |

---

## Follow-Up Features (Future)

- [ ] Hook-based plan validation (warn if plan.md missing on "continue implementation")
- [ ] Hook-based git blame integration (show last commit context)
- [ ] Telemetry hooks for Superpowers usage analytics (opt-in)
- [ ] GitHub Actions integration for CI enforcement

---

## References

- GitHub Copilot CLI Hooks Documentation: [Link]
- obra/superpowers Claude Code hooks: [Reference implementation]
- Superpowers Iron Law: [docs/SKILLS_REFERENCE.md]
- Loop of Autonomy: [.github/copilot-instructions.md]
