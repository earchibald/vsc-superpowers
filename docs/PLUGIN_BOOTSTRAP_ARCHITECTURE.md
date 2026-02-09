# Superpowers Plugin: Hybrid Bootstrap Architecture

## Overview

The Superpowers plugin uses a **hybrid bootstrap architecture** that provides:
- **Efficiency**: Shared cache for single source of truth across projects
- **Resilience**: Bundled skills ensure plugin works even if cache unavailable
- **Simplicity**: Automatic bootstrap on first use

## Architecture Diagram

```
Plugin Installation
        ↓
   First Use?
      / \
    Yes  No
    /     \
   ↓       └→ ~/.cache/superpowers exists?
Bootstrap       / \
(runs once)   Yes  No
   ↓           ↓    ↓
   ↓        Use   Fallback
   ↓       Cache  Bundled
   ↓         ↓      ↓
   └─────────┴──────┤
         All Agree: Use Bundled (.agents/skills/)
         But Prefer: Cache (~/.cache/superpowers/)
```

## Three Layers

### Layer 1: Bundled Skills (`.agents/skills/*/SKILL.md`)

**What:** All 14 skills included directly in plugin package
**When:** Always available as fallback
**Benefit:** Plugin works standalone, no external dependencies
**Drawback:** Duplicate content, harder to sync updates

```
vsc-superpowers/.agents/skills/
├── brainstorm/SKILL.md
├── tdd/SKILL.md
└── [12 more]...
```

### Layer 2: Bootstrap Script (`.agents/bootstrap-superpowers.sh`)

**What:** Initializes `~/.cache/superpowers` from upstream obra/superpowers
**When:** Runs automatically on first use if cache missing
**Output:** `~/.cache/superpowers/skills` with all shared skills
**Benefit:** Establishes single source of truth

```bash
#!/bin/bash
# On first use, creates ~/.cache/superpowers if missing
exec git clone https://github.com/obra/superpowers.git ~/.cache/superpowers
```

### Layer 3: Symlink Strategy (`.agents/manifest.json`)

**What:** Plugin manifest that chooses which source to use
**Priority:**
1. If `~/.cache/superpowers/skills` exists → use cache via symlink (primary)
2. If cache missing → use bundled `.agents/skills/` (fallback)
3. Bootstrap on first use (automatic)

```json
{
  "skills": {
    "source": "hybrid",
    "bundled-skills-path": ".agents/skills",
    "cache-path": "~/.cache/superpowers/skills",
    "bootstrap": {
      "script": ".agents/bootstrap-superpowers.sh"
    }
  }
}
```

## User Flows

### Flow 1: New User (First Install)

```
1. copilot plugin add https://github.com/earchibald/vsc-superpowers
   ↓
2. copilot "help me debug this"
   ↓
3. Plugin initialization:
   - Check ~/.cache/superpowers? [NO]
   - Run bootstrap script? [YES, auto]
   ↓
4. bootstrap-superpowers.sh:
   - git clone obra/superpowers → ~/.cache/superpowers
   ↓
5. Plugin ready:
   - Link .agents/skills → ~/.cache/superpowers/skills
   - Load all 14 skills from cache
   ↓
6. Skills available for future use
```

### Flow 2: Returning User (Cache Exists)

```
1. copilot "I need a TDD approach"
   ↓
2. Plugin initialization:
   - Check ~/.cache/superpowers? [YES]
   - Bootstrap needed? [NO]
   ↓
3. Plugin ready:
   - Skip bootstrap (already done)
   - Link to existing cache
   - Load skills directly
   ↓
4. Instant skill availability (efficient)
```

### Flow 3: Cache Deleted / Reset

```
1. rm -rf ~/.cache/superpowers
   ↓
2. copilot "any prompt"
   ↓
3. Plugin detects:
   - Cache missing
   - Bundled skills available? [YES]
   ↓
4. Options:
   a) Auto-bootstrap (recommended): Restore cache from upstream
   b) Use bundled: Work with plugin-included skills
   ↓
5. User's choice determines next session
```

## Bootstrap Script Behavior

```bash
~/.cache/superpowers/plugin/bootstrap-superpowers.sh

# Detects:
# - Cache already exists? → Exit with success message
# - Cache missing? → Clone from github.com/obra/superpowers

# On success:
# - ~/.cache/superpowers/skills/ populated
# - Ready for symlinking

# On failure:
# - Exit with helpful error message
# - Suggest manual bootstrap: git clone ...
# - Fallback to bundled skills still works
```

## Manifest Configuration

```json
{
  "initialization": {
    "on-first-use": "Run bootstrap script if cache doesn't exist",
    "behaviors": [
      "Load bundled skills from .agents/skills",
      "Link to ~/.cache/superpowers/skills if cache exists after bootstrap",
      "Fall back to bundled if cache unavailable"
    ]
  }
}
```

Manifest tells plugin:
1. **On startup:** Check cache status
2. **If missing:** Run bootstrap automatically
3. **If present:** Use cache via symlink
4. **If bootstrap fails:** Use bundled skills (never breaks)

## Benefits of Hybrid Approach

| Benefit | How Achieved |
|---------|-------------|
| **Efficiency** | Cache symlink = single copy, fast loading |
| **Single Source** | All projects use `.cache/superpowers` |
| **Auto-Updates** | `git pull` in cache updates all projects |
| **Resilience** | Bundled skills work if cache unavailable |
| **No Lock-in** | Users control whether to use cache or bundled |
| **Automatic** | Bootstrap runs invisibly on first use |
| **Portable** | Plugin works offline after bootstrap |

## Comparison to Alternatives

### Option A: Bundled Only ❌
- ✗ Duplicate content across versions
- ✗ Hard to sync updates
- ✗ Large plugin size
- ✗ No single source of truth

### Option B: Cache Only ❌
- ✗ Plugin doesn't work without bootstrap
- ✗ Requires user knowledge
- ✗ Brittle on cache deletion

### Option C: Hybrid Bootstrap ✅ (Selected)
- ✓ Efficient after bootstrap
- ✓ Works standalone if needed
- ✓ Auto-bootstrap hides complexity
- ✓ Single source of truth when possible
- ✓ Graceful degradation
- ✓ Powers both plugin and VS Code workflows

## Implementation Checklist

- [x] Create `.agents/skills/*/SKILL.md` (14 skills bundled)
- [x] Create `.agents/bootstrap-superpowers.sh` (bootstrap script)
- [x] Create `.agents/manifest.json` (plugin configuration)
- [ ] Test plugin initialization flow
- [ ] Test cache detection and symlink creation
- [ ] Test bootstrap script execution
- [ ] Test fallback to bundled skills
- [ ] Test CLI skill invocation
- [ ] Document plugin installation
- [ ] Publish to plugin marketplace

## Files Created

```
.agents/
├── skills/             # Bundled skills (14 dirs, each with SKILL.md)
│   ├── brainstorm/SKILL.md
│   ├── tdd/SKILL.md
│   └── [12 more]...
├── bootstrap-superpowers.sh    # Bootstrap script
├── manifest.json               # Plugin manifest
└── PLUGIN_README.md           # Plugin documentation
```

## Next Steps

1. **Test Bootstrap**: Verify script runs and creates cache correctly
2. **Test Plugin Loading**: Verify manifest is recognized by Copilot CLI
3. **Test Skill Discovery**: Verify skills are found and loaded
4. **Test Fallback**: Verify bundled skills work if cache unavailable
5. **Documentation**: Update main README with plugin installation
6. **Distribution**: Prepare GitHub release / NPM package

---

This hybrid approach balances simplicity (auto-bootstrap), efficiency (shared cache), and resilience (bundled fallback).
