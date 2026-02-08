# Superpowers Installer v2: Symlink-Based Installation Design

**Date:** February 8, 2026  
**Status:** Validated  
**Issue:** [#1 - Feature: installer should install symlink to global cache](https://github.com/earchibald/vsc-superpowers/issues/1)

## Problem Statement

Currently, the installer caches Superpowers skills at `~/.cache/superpowers/` (outside the workspace). This causes VS Code to repeatedly prompt users for file access permissions when Copilot tries to read skill files. Users are "harassed" with permission dialogs even though they only want to safely read their skills.

## Design Goal

Keep all Superpowers content within the workspace using workspace-relative paths (`./.superpowers/`), eliminating permission prompts while maintaining a single global source of truth for efficient disk usage.

## Solution Architecture

### Path Structure

**Before (Current):**
```
~/.cache/superpowers/               ← Global cache (outside workspace)
  skills/
    writing-plans/
    systematic-debugging/
    ... (14 skills)
    
./vsc-superpowers/                  ← Workspace
  .github/
    copilot-instructions.md         ← References ~/.cache/superpowers/
    prompts/                        ← Copies of skills
```

**After (Proposed):**
```
~/.cache/superpowers/               ← Global cache (single source of truth)
  skills/
    writing-plans/
    systematic-debugging/
    ... (14 skills)
    
./vsc-superpowers/                  ← Workspace
  .superpowers → ~/.cache/superpowers/  ← Symlink (workspace-relative access)
  .github/
    copilot-instructions.md         ← References ./.superpowers/skills/
    prompts/                        ← Copies of skills
```

## Installation Flow

### 1. PREVIEW PHASE (No Changes Yet)

Display a summary of what will be installed:

```
🔍 PREVIEW: Superpowers Installation Plan
═══════════════════════════════════════════════════════════════

📦 GLOBAL CACHE
  Location: ~/.cache/superpowers/
  Action: Clone/update repository
  Size: ~5-10 MB

🔗 WORKSPACE SYMLINK
  Location: ./.superpowers/
  Target: ~/.cache/superpowers/
  Action: Create symlink (workspace-resident)

📝 INSTRUCTIONS UPDATE
  File: ./.github/copilot-instructions.md
  Action: Update skill paths to ./.superpowers/skills/

⚠️  CONFLICTS DETECTED
  • Existing .superpowers directory → will back up to .superpowers.old

✅ Ready to proceed? (Y/N)
```

### 2. DETECTION & ADAPTATION

**Check workspace state:**
- If `.superpowers` exists:
  - If correct symlink → skip creation, log "already installed"
  - If regular directory → back up to `.superpowers.old`
  - If wrong symlink → remove and recreate correct one
- Check global cache state:
  - If not exists → clone from repo
  - If exists → pull latest version

**Output:**
```
✓ .superpowers detected as regular directory
  → Backing up to .superpowers.old
✓ Global cache at ~/.cache/superpowers already up to date
```

### 3. EXECUTION PHASE

**Steps executed in order:**
1. Update/clone global cache: `git clone/pull https://github.com/obra/superpowers ~/.cache/superpowers`
2. Create symlink: `ln -s ~/.cache/superpowers ./.superpowers`
3. Update instructions file with workspace-relative paths
4. Copy skill prompt files to `.github/prompts/`

**Key implementation detail:** Use `ln -s ~/.cache/superpowers ./.superpowers` (absolute target, relative from workspace perspective)

### 4. CONFIRMATION PHASE

Display what was installed:

```
✅ INSTALLATION COMPLETE
═══════════════════════════════════════════════════════════════

🔗 Symlink created
  ./.superpowers → ~/.cache/superpowers/

📝 Instructions updated
  ./.github/copilot-instructions.md (paths now use ./.superpowers/)

🛠️  Skills installed to prompts
  /brainstorm, /write-plan, /tdd, /investigate, /verify, 
  /worktree, /finish-branch, /review, /receive-review,
  /subagent-dev, /dispatch-agents, /write-skill, /superpowers

👉 NEXT STEP: Reload VS Code
   Command Palette → "Developer: Reload Window"
```

## Path Changes in copilot-instructions.md

**Instruction references will change from:**
```markdown
Read the skills at ~/.cache/superpowers/skills/writing-plans/SKILL.md
```

**To:**
```markdown
Read the skills at ./.superpowers/skills/writing-plans/SKILL.md
```

This keeps all references workspace-local, preventing permission prompts.

## Idempotency & Safety

- **Idempotent:** Running installer multiple times is safe
  - Detects existing symlink, skips if correct
  - Backs up conflicting directories with `.old` suffix
  - Updates existing instructions file via tag replacement

- **Reversible:** User can restore with `rm .superpowers && mv .superpowers.old .superpowers`

- **Non-destructive:** Only adds/updates `.github/` and creates symlink; doesn't touch other workspace files

## Files Modified by Installer

1. `./.superpowers` - **Created** (symlink)
2. `./.github/copilot-instructions.md` - **Updated** (path references)
3. `./.github/prompts/*.prompt.md` - **Updated** (skill copies)

## Backup Artifacts

- `.superpowers.old` - If existing `.superpowers` directory backed up
- `.github/copilot-instructions.md.old` - If unmanaged instructions found (existing tag-based replacement reuses existing file)

## User Communication

All changes are:
- **Previewed** before execution
- **Labeled clearly** in installer output (✓ for success, ⚠️ for warnings, ❌ for errors)
- **Logged** with file paths and intentions
- **Reversible** with documented backup names

## Testing Criteria

- ✅ Symlink created pointing to `~/.cache/superpowers`
- ✅ No permission prompts when Copilot reads skills
- ✅ Installer runs idempotently (second run detects existing symlink)
- ✅ Backup created if `.superpowers` already exists
- ✅ Instructions updated to use `./.superpowers/skills/` paths
- ✅ All 14 skills accessible via `/` commands after reload
- ✅ Rollback possible by removing symlink and restoring `.superpowers.old`

---

**Ready for implementation planning?**
