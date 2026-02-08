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

See [docs/SKILLS_REFERENCE.md](docs/SKILLS_REFERENCE.md) for detailed descriptions.

## Command Mapping

Some skills use different names to avoid conflicts with VS Code reserved commands:

- `/write-plan` (instead of `/plan`) 
- `/investigate` (instead of `/fix`)

## Verification

```bash
./scripts/verify-installation.sh
```

## Updating

```bash
./install-superpowers.sh
```

The installer is idempotent - run it anytime to update to the latest version.

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

## Credits

Built on [Superpowers](https://github.com/obra/superpowers) by [@obra](https://github.com/obra).

## License

MIT License - see LICENSE file for details
