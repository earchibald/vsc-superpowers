# Implementation Plan: Symlink-Based Installer (Issue #1)

**Date:** February 8, 2026  
**Worktree:** `/Users/earchibald/work/vsc-superpowers-feature`  
**Branch:** `feature/symlink-installer`  
**Status:** In Progress

---

## Overview

Refactor `install-superpowers.sh` to use workspace-relative symlinks instead of global cache paths. This eliminates VS Code permission prompts while keeping skills in a single global cache.

## Implementation Tasks

### Task 1: Refactor Installer - Preview Phase
**Time:** 15-20 minutes  
**Files:** `install-superpowers.sh`

Create the preview function that shows what will be installed without making changes.

**Acceptance Criteria:**
- [ ] Function displays: global cache location, symlink target, files to update
- [ ] Shows conflicts (existing `.superpowers`, old `.github/` files)
- [ ] Prompts user for confirmation (Y/N)
- [ ] Does not make any filesystem changes
- [ ] Output is readable and clearly labeled

**Code Location:** After line 20, before cache setup
**Commands to verify:**
```bash
./install-superpowers.sh  # Should show preview and ask for confirmation
```

---

### Task 2: Refactor Installer - Detection & Adaptation
**Time:** 15-20 minutes  
**Files:** `install-superpowers.sh`

Add detection logic to handle existing symlinks and backup conflicting directories.

**Acceptance Criteria:**
- [ ] Detects if `.superpowers` already exists
- [ ] If correct symlink: logs "already installed" and skips creation
- [ ] If regular directory: backs up to `.superpowers.old`
- [ ] If wrong symlink: removes and recreates correct one
- [ ] Pulls latest global cache or clones if missing
- [ ] All detection is logged clearly

**Code Location:** After confirmation, before execution
**Commands to verify:**
```bash
mkdir .superpowers-test && ./install-superpowers.sh  # Should back up existing
```

---

### Task 3: Refactor Installer - Symlink Creation
**Time:** 10-15 minutes  
**Files:** `install-superpowers.sh`

Execute symlink creation with error handling.

**Acceptance Criteria:**
- [ ] Creates symlink: `ln -s ~/.cache/superpowers ./.superpowers`
- [ ] Uses absolute path (not relative) as target
- [ ] Verifies symlink points correctly after creation
- [ ] Provides clear error if symlink creation fails
- [ ] Works when `.superpowers.old` exists

**Code Location:** In execution phase, after global cache setup
**Commands to verify:**
```bash
ls -la .superpowers  # Should show -> ~/.cache/superpowers
stat .superpowers    # Should confirm symlink target
```

---

### Task 4: Update Instructions File - Path Replacement
**Time:** 15-20 minutes  
**Files:** `install-superpowers.sh`, `.github/copilot-instructions.md`

Update instruction references to use workspace-relative `./.superpowers/` paths.

**Acceptance Criteria:**
- [ ] Replaces `~/.cache/superpowers/skills/` with `./.superpowers/skills/` in instructions
- [ ] Only replaces within the SUPERPOWERS-START/END tags
- [ ] Preserves all other instruction content
- [ ] Idempotent: running twice produces same result
- [ ] Creates `.github/copilot-instructions.md.old` only if migrating

**Code Location:** After symlink creation, before prompt installation
**Files affected:** `.github/copilot-instructions.md`
**Commands to verify:**
```bash
grep "./.superpowers/skills/" .github/copilot-instructions.md  # Should find matches
```

---

### Task 5: Installer - Confirmation & Logging
**Time:** 10-15 minutes  
**Files:** `install-superpowers.sh`

Add final confirmation output showing what was installed.

**Acceptance Criteria:**
- [ ] Shows symlink created at `./.superpowers`
- [ ] Lists all 14 skills installed
- [ ] Shows file paths that were modified
- [ ] Displays next step: "Reload VS Code → Developer: Reload Window"
- [ ] Uses consistent emoji/formatting for readability
- [ ] Output is scrollable and complete

**Code Location:** At end of script
**Commands to verify:**
```bash
./install-superpowers.sh 2>&1 | tail -20  # Should show confirmation
```

---

### Task 6: Test - Existing Symlink Detection
**Time:** 10 minutes  
**Files:** Test script (manual)

Verify installer handles various existing `.superpowers` states.

**Acceptance Criteria:**
- [ ] Correctly installed symlink detects as "already installed"
- [ ] Regular directory backs up to `.superpowers.old`
- [ ] Broken symlink is removed and recreated
- [ ] Installer runs idempotently (second run is no-op)

**Test Scenarios:**
```bash
# Scenario 1: Clean run
rm -rf .superpowers .superpowers.old
./install-superpowers.sh

# Scenario 2: Second run (should detect existing)
./install-superpowers.sh

# Scenario 3: Directory exists (should back up)
rm .superpowers
mkdir .superpowers
./install-superpowers.sh
ls -la .superpowers.old  # Should exist

# Scenario 4: Verify symlink target
ls -la .superpowers  # Should show -> ~/.cache/superpowers
```

---

### Task 7: Test - Path References in Instructions
**Time:** 10 minutes  
**Files:** `.github/copilot-instructions.md`

Verify all skill path references use workspace-relative paths.

**Acceptance Criteria:**
- [ ] No remaining `~/.cache/superpowers/` paths in instructions
- [ ] All skill references use `./.superpowers/skills/`
- [ ] Symlink resolves correctly to actual files
- [ ] Instructions file is valid markdown

**Commands to verify:**
```bash
# Check for old paths
grep "~/.cache/superpowers" .github/copilot-instructions.md
# Should return nothing

# Verify symlink resolution
cat .superpowers/skills/writing-plans/SKILL.md | head -5
# Should show skill content from global cache
```

---

### Task 8: Integration Test - Full Installation
**Time:** 15 minutes  
**Files:** Test in clean workspace

Test installer in a fresh workspace environment.

**Acceptance Criteria:**
- [ ] Installer runs without errors
- [ ] Symlink created and resolves correctly
- [ ] All 14 slash commands available in VS Code after reload
- [ ] No permission prompts when Copilot reads skills
- [ ] Preview accurately reflects what gets installed

**Test Steps:**
```bash
cd ~/tmp
git clone https://github.com/earchibald/vsc-superpowers test-install
cd test-install
git checkout feature/symlink-installer
./install-superpowers.sh
# Follow prompts and verify each step
```

---

### Task 9: Documentation - Update Installer Comments
**Time:** 10 minutes  
**Files:** `install-superpowers.sh`, `README.md`

Update installer script comments and main README to explain new symlink approach.

**Acceptance Criteria:**
- [ ] Script header explains symlink strategy
- [ ] README mentions `.superpowers` as workspace-resident
- [ ] Installation instructions unchanged (still one command)
- [ ] Troubleshooting section added for symlink issues

**Documentation changes:**
- Add section: "How Symlinks Work (Permission-Free)"
- Add troubleshooting: "If permission prompts still appear, verify symlink"
- Update installer comments with new phase names

---

## Testing Strategy

**Manual testing** (before automation):
1. Clean environment: remove all Superpowers files
2. Run preview: verify output matches design
3. Accept installation
4. Verify symlink created
5. Check instructions updated
6. Reload VS Code and test `/brainstorm` command
7. Monitor console for permission prompts (should be none)

**Automated testing** (if applicable):
- Add `scripts/test-installer.sh` to verify clean and idempotent runs
- Verify backup behavior

---

## Rollback Plan

If anything goes wrong:

```bash
# Remove symlink
rm .superpowers

# Restore backed-up directory
mv .superpowers.old .superpowers

# Restore old instructions (if migrated)
mv .github/copilot-instructions.md .github/copilot-instructions.md.new
mv .github/copilot-instructions.md.old .github/copilot-instructions.md
```

---

## Verification Checklist

After all tasks complete:

- [ ] Installer shows preview before confirming
- [ ] Symlink created at `./.superpowers`
- [ ] All paths in instructions use `./.superpowers/skills/`
- [ ] No `~/.cache/superpowers/` references in workspace
- [ ] Installer is idempotent (runs safely twice)
- [ ] Backups created for conflicting files
- [ ] All 14 skills accessible via `/` commands
- [ ] No permission prompts in VS Code
- [ ] README updated with explanation
- [ ] Commit message references issue #1

---

**Ready to begin implementation?**
