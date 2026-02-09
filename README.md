# Superpowers for VS Code & Copilot CLI

An implementation of the [Superpowers](https://github.com/obra/superpowers) framework for GitHub Copilot, providing all 14 core skills as **native slash commands in VS Code** and as a **plugin for Copilot CLI**.

## What is Superpowers?

Superpowers is a complete software development workflow for coding agents, built on a set of composable "skills" that enforce best practices like TDD, systematic debugging, and comprehensive planning.

## Two Ways to Use

**VS Code Copilot Chat** - Natural language interface that infers framework patterns from context. Slash commands (`/write-plan`, `/tdd`, etc.) also available for explicit invocation.

**Copilot CLI Plugin** - Natural language or direct skill invocation in terminal via `.agents/` plugin architecture with auto-bootstrap

*Same 14 skills, same natural language interface - both environments understand Superpowers without explicit commands.*

---

## 🙏 Credit & Support

**This project exists because of [Jesse Vincent (@obra)](https://github.com/obra) and the incredible [Superpowers](https://github.com/obra/superpowers) framework.**

Jesse created a paradigm-shifting approach to agent-driven development—systematic, principled, and focused on evidence over assumptions. This VS Code implementation is built entirely on that foundation.

**If you find Superpowers valuable:**
- ⭐ **Star the original** [Superpowers repository](https://github.com/obra/superpowers)
- 📖 **Read the original** [Superpowers project](https://github.com/obra/superpowers) for the complete vision
- 🙌 **Support Jesse's work** - follow [@obra](https://github.com/obra) and contribute to the original project

The Superpowers approach transforms how we think about code quality, testing, and agent collaboration. Thank you, Jesse, for creating something that genuinely improves how we build software.

---

## Installation

### Option 1: VS Code Copilot Chat (Natural Language + Slash Commands)

**Per-Workspace Installation:** Superpowers installs into each workspace separately because it relies on workspace-specific `.github/copilot-instructions.md` that VS Code Copilot reads.

```bash
# One-line install (run from your workspace root)
cd /path/to/your/project
curl -fsSL https://raw.githubusercontent.com/earchibald/vsc-superpowers/main/install-superpowers.sh | bash

# Or clone installer to your workspace and run
cd /path/to/your/project
git clone https://github.com/earchibald/vsc-superpowers.git .superpowers-installer
cd .superpowers-installer
./install-superpowers.sh
cd ..

# Reload VS Code to activate
# Command Palette > Developer: Reload Window
```

**Why per-workspace?** VS Code Copilot reads `.github/copilot-instructions.md` from your workspace root. Each project needs its own Superpowers installation to get the framework behaviors.

### Option 2: Copilot CLI Plugin

```bash
# Install directly from repository
copilot plugin add https://github.com/earchibald/vsc-superpowers

# On first use, the plugin automatically bootstraps:
# - Clones obra/superpowers to ~/.cache/superpowers
# - Links plugin skills to shared cache
# - Falls back to bundled skills if cache unavailable
```

**Note:** Both installations can coexist - use slash commands in VS Code and natural language in terminal.

**Background Agent Limitation:** VS Code's background agent does not currently have access to Copilot CLI plugins. This is a separate issue being tracked and does not affect the primary VS Code Chat or CLI terminal workflows.

### How VS Code Installation Works

The installer uses a **per-workspace installation** approach with shared cache:

1. **Preview Phase**: Shows what will be installed in your workspace and asks for confirmation
2. **Global Cache**: Clones Superpowers to `~/.cache/superpowers` (shared across all your workspaces)
3. **Workspace Symlink**: Creates `./.superpowers → ~/.cache/superpowers` in your workspace
4. **Instructions File**: Creates `.github/copilot-instructions.md` with Superpowers framework protocol **in your workspace**
5. **Path Updates**: Instructions reference `./.superpowers/skills/` (workspace-relative paths)
6. **Prompts**: Copies skill definitions to `.github/prompts/` **in your workspace**

**Result:** Copilot reads framework instructions from **your workspace's** `.github/copilot-instructions.md` and **infers patterns naturally**. Slash commands in `.github/prompts/` available for explicit invocation. All paths workspace-relative, **eliminating permission prompts**.

**Cache Efficiency:** Multiple workspaces share `~/.cache/superpowers`, so you only download Superpowers once. Each workspace gets its own `.github/` configuration but references the shared cache.

## Available Skills (14 Total)

**Preferred interface:** Use natural language - Copilot infers the correct patterns from context. Slash commands available for explicit invocation when needed.

All 14 Superpowers skills:

- `/write-plan` - Create detailed implementation plans
- `/execute-plan` - Execute plans with checkpoints  
- `/brainstorm` - Refine ideas through dialogue
- `/tdd` - Enforce strict TDD cycles
- `/investigate` - Systematic debugging
- `/verify` - Verify fixes work
- `/worktree` - Create isolated workspaces
- `/finish-branch` - Complete branch workflows
- `/review` - Request code review
- `/receive-review` - Respond to feedback
- `/subagent-dev` - Task-by-task development
- `/dispatch-agents` - Parallel agent workflows
- `/write-skill` - Create new skills
- `/superpowers` - Learn the system

### 📖 Quick Reference

**Start here:** [docs/CHEATSHEET.md](docs/CHEATSHEET.md) - Quick one-liners for all 14 skills, workflow diagrams, and decision trees. Perfect for learning workflows and remembering what skill to use.

**Deep dive:** [docs/SKILLS_REFERENCE.md](docs/SKILLS_REFERENCE.md) - Detailed descriptions of each skill with examples and anti-patterns.

## Copilot CLI Hooks (Iron Law Enforcement)

**Available in:** Copilot CLI only (not VS Code Copilot Chat)

Superpowers includes a **Copilot CLI plugin** with hooks that automatically enforce the **Iron Law of Verification**: "Never commit without running tests."

### Architecture

The `hooks/` directory contains a Copilot CLI plugin with two hooks:

**1. `sessionStart` - Bootstrap Hook**
- Fires when you start a Copilot CLI session
- Clones/updates `obra/superpowers` cache to `~/.cache/superpowers`
- Displays "🦸 Superpowers Active" banner
- Network failures don't block session (always exits 0)

**2. `preToolUse` - Iron Law Guard**
- Fires before Copilot CLI executes bash commands
- Detects dangerous operations: `git commit`, `git push`
- Checks for verification marker: `/tmp/.superpowers-verified-{project_hash}`
- **Warns if:**
  - No verification marker exists (tests haven't been run)
  - Marker is stale (>1 hour old)
- **Always exits 0** - educates with warnings, doesn't block execution

### How Verification Works

1. **Run tests:** `tests/hooks/run-all-tests.sh`
2. **Tests pass:** Creates `/tmp/.superpowers-verified-{hash}` with timestamp
3. **Tests fail:** Removes verification marker
4. **Commit attempt:** Hook checks marker, warns if missing/stale
5. **Marker expires:** After 1 hour, re-run tests to refresh

**Project isolation:** Each workspace gets unique marker based on MD5 hash of project path. Multiple projects don't interfere.

### Example Workflow

```bash
# Start copilot session - hook bootstraps cache
$ copilot
🦸 Superpowers Active

# Make changes to code
$ copilot "implement user authentication"
[...copilot generates code...]

# Try to commit without testing
$ copilot "commit these changes"
⚠️  Warning: No verification marker found
⚠️  Run tests before committing (Iron Law of Verification)
[commit proceeds with warning]

# Run tests first
$ tests/hooks/run-all-tests.sh
✅ All tests passed!
✅ Verification marker created: /tmp/.superpowers-verified-a1b2c3...

# Now commit without warning
$ copilot "commit these changes"
[commit proceeds silently]
```

### Technical Details

**Verification Markers:**
- Location: `/tmp/.superpowers-verified-{project_hash}`
- Format: Unix timestamp (seconds since epoch)
- Expiration: 3600 seconds (1 hour)
- Created: When test runners complete successfully
- Removed: When tests fail or marker expires

**Hook Implementation:**
- Language: Bash (compatible with macOS/Linux)
- JSON Parsing: Uses `jq` if available, falls back to `grep`/`sed`
- Error Handling: All failures exit 0 (non-blocking)
- Testing: 34/35 tests passing (97.1% coverage)

**Test Runners Supporting Markers:**
- `tests/hooks/run-all-tests.sh` (master test runner)
- Add to your test scripts: `source tests/hooks/verification-lib.sh`

### Testing the Hooks

```bash
# Run all hook tests
tests/hooks/run-all-tests.sh

# Test specific suites
tests/hooks/session-start.test.sh      # Bootstrap hook
tests/hooks/pre-command.test.sh        # Iron Law enforcement
tests/hooks/verification-marker.test.sh # Marker lifecycle
tests/hooks/integration.test.sh        # End-to-end integration
```

### Disabling Hooks

If you need to disable verification warnings:

```bash
# Temporarily disable preToolUse hook
mv .github/hooks/scripts/pre-command.sh .github/hooks/scripts/pre-command.sh.disabled

# Re-enable
mv .github/hooks/scripts/pre-command.sh.disabled .github/hooks/scripts/pre-command.sh
```

**Note:** Hooks educate but never block - you can always commit. The warnings help maintain the TDD discipline that makes Superpowers effective.

## Usage Patterns

### VS Code Copilot Chat

**Natural Language (Recommended):**
- "I want to add authentication to this project" → Infers planning workflow
- "Let's implement password validation with TDD" → Infers test-first development
- "The tests are failing with TypeError" → Infers systematic investigation

**Slash Commands (Explicit):**
- `/write-plan` (instead of `/plan` - VS Code reserved)
- `/investigate` (instead of `/fix` - VS Code reserved)

### Copilot CLI Plugin

**Natural Language or Direct Skills:**
- "create a plan" or "write-plan"
- "debug this issue" or "investigate"

## Verification

### Check Installation

**Ask Copilot:**
```
What is Superpowers? Explain the Loop of Autonomy.
```

If Copilot describes the framework correctly, installation is working.

**Run Test Scripts:**
```bash
# VS Code installation check
./scripts/verify-installation.sh

# CLI plugin tests
./scripts/test-plugin.sh
./scripts/test-copilot-cli.sh
```

## Troubleshooting

### Permission Prompts Still Appearing

If VS Code continues to ask for file access permissions:

1. **Verify symlink**: `ls -la .superpowers` should show `-> ~/.cache/superpowers`
2. **Check instructions**: `grep "./.superpowers/skills" .github/copilot-instructions.md`
3. **Reload VS Code**: Command Palette > "Developer: Reload Window"
4. **Re-run installer**: `./install-superpowers.sh`

### Skills Not Appearing in Slash Commands

1. **Reload VS Code**: Command Palette > "Developer: Reload Window"
2. **Check prompts directory**: `ls -la .github/prompts/ | grep prompt`
3. **Verify 14 skills**: `ls -1 .github/prompts/*.prompt.md | wc -l`

### Broken Installation

To reset:

```bash
# Remove symlink
rm ./.superpowers

# Restore backup if exists
mv ./.superpowers.old ./.superpowers

# Remove generated files
rm -rf .github/prompts/

# Run installer again
./install-superpowers.sh
```

## Updating

```bash
./install-superpowers.sh
```

The installer is idempotent - run it anytime to update to the latest version.

## Economics: Superpowers for Cost-Effective VS Code Copilot

VS Code Copilot's per-request billing model (each slash command invocation = 1 credit) contrasts sharply with token-based pricing in other platforms. Superpowers transforms this into an advantage.

**The Economics:**

- **Without Superpowers**: Frequent context-switching between small prompts → many requests → higher costs
- **With Superpowers**: Fewer, larger batches (`/write-plan`, `/tdd`, `/subagent-dev`) → fewer requests → lower cost per unit of work

Example: A typical feature implementation:
- **Ad-hoc approach**: `/write-plan` (1 credit) → `/tdd` per-task (5 credits) → `/review` (1 credit) → debugging (`/investigate` 2-3 credits) = ~9 credits
- **Superpowers approach**: `/write-plan` (1 credit) → `/subagent-dev` per task batch (2-3 credits, handling multiple tasks) → `/verify` (1 credit) = ~4-5 credits

**The quality gain:** While reducing requests, Superpowers *increases* output fidelity through:
- Sustained context across long-running prompts
- Systematic workflows (TDD, debugging, planning) that prevent rework
- Batch processing that clusters related tasks together

**Result:** You get better code, lower costs, and maintain the high-fidelity output quality that makes Superpowers valuable, all while being pragmatic about per-request billing.

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

## Credits

Built on [Superpowers](https://github.com/obra/superpowers) by [@obra](https://github.com/obra).

## License

MIT License - see LICENSE file for details
