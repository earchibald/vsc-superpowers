# VS Code Superpowers

An implementation of the [Superpowers](https://github.com/obra/superpowers) framework for GitHub Copilot in VS Code, providing all 14 core skills as native slash commands.

## What is Superpowers?

Superpowers is a complete software development workflow for coding agents, built on a set of composable "skills" that enforce best practices like TDD, systematic debugging, and comprehensive planning.

## Installation

```bash
# Clone this repository
git clone https://github.com/earchibald/vsc-superpowers.git
cd vsc-superpowers

# Run the installer
./install-superpowers.sh

# Reload VS Code
# Command Palette > Developer: Reload Window
```

### How Installation Works

The installer uses a **workspace-resident symlink approach** to prevent permission prompts:

1. **Preview Phase**: Shows what will be installed and asks for confirmation
2. **Global Cache**: Clones Superpowers to `~/.cache/superpowers` (shared across workspaces)
3. **Workspace Symlink**: Creates `./.superpowers → ~/.cache/superpowers` (workspace-local)
4. **Path Updates**: Instructions reference `./.superpowers/skills/` (no absolute paths)
5. **Prompts**: Copies skill definitions to `.github/prompts/` for slash commands

**Result:** Copilot reads all skills from workspace-local paths, **eliminating permission prompts** while keeping the global cache for efficiency.

### Backup & Recovery

If a `.superpowers` directory already exists, the installer backs it up to `.superpowers.old`. To restore:

```bash
rm .superpowers
mv .superpowers.old .superpowers
```

## Available Skills (14 Total)

All 14 Superpowers skills are available as slash commands:

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

## Command Mapping

Some skills use different names to avoid conflicts with VS Code reserved commands:

- `/write-plan` (instead of `/plan`) 
- `/investigate` (instead of `/fix`)

## Verification

```bash
./scripts/verify-installation.sh
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
