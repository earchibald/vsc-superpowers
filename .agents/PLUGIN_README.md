# Superpowers Plugin for Copilot CLI

Superpowers Agent Skills plugin enables systematic development practices across Copilot CLI and other agents.

## Installation

```bash
copilot plugin add https://github.com/earchibald/vsc-superpowers
```

## First Use: Bootstrap

On first use, the plugin will automatically bootstrap the Superpowers cache:

```bash
# On first invocation:
copilot "Let me debug this test failure"

# Plugin detects:
# - ~/.cache/superpowers doesn't exist
# - Runs: .agents/bootstrap-superpowers.sh
# - Clones obra/superpowers to cache
# - Links plugin skills to cache
# - Ready to use
```

Manual bootstrap if needed:

```bash
~/.cache/superpowers/plugin/bootstrap-superpowers.sh
```

## Architecture: Hybrid Workflow

### First Time (Bootstrap)
```
User installs plugin
    ↓
.agents/bootstrap-superpowers.sh runs
    ↓
~/.cache/superpowers created (from obra/superpowers)
    ↓
Plugin links to cache
```

### Subsequent Uses (Efficient)
```
Plugin checks ~/.cache/superpowers
    ↓
Cache exists → use symlink (efficient)
    ↓
All 14 skills load from shared cache
```

### If Cache Deleted (Resilient)
```
Plugin detects missing cache
    ↓
Fall back to bundled skills (.agents/skills/*/SKILL.md)
    ↓
Bootstrap runs again or user manually restores
```

## Skills Included (14 Total)

**Process Skills:**
- `brainstorm` - Generate creative solutions
- `write-plan` - Create implementation plans
- `superpowers` - Learn Superpowers capabilities

**Implementation Skills:**
- `tdd` - Test-driven development
- `execute-plan` - Execute plans with checkpoints
- `subagent-dev` - Dispatch subagents per task

**Quality & Verification:**
- `investigate` - Systematic debugging
- `verify` - Verification before completion
- `review` - Request code review
- `receive-review` - Respond to review feedback

**Workflow Management:**
- `worktree` - Create isolated workspaces
- `finish-branch` - Merge/PR/discard work
- `dispatch-agents` - Run parallel workflows

**Advanced:**
- `write-skill` - Create new skills

## Usage

### Interactive Mode

```bash
copilot
> I need to debug why this test is failing
# Automatically suggests investigate + tdd skills
# Load relevant skills and guide systematic debugging
```

### Programmatic Mode

```bash
copilot -p "I need to implement a new feature"
# Plugin auto-selects: brainstorm, write-plan, execute-plan skills
# Provides context-aware guidance
```

### Direct Skill Invocation (Future)

```bash
copilot skill tdd
# Loads TDD skill directly in interactive mode
```

## Cache Management

### Update Cache

```bash
cd ~/.cache/superpowers && git pull
```

### Backup Cache

```bash
cp -r ~/.cache/superpowers ~/.cache/superpowers.backup
```

### Reset Bootstrap

```bash
rm -rf ~/.cache/superpowers
# Next plugin use will re-bootstrap automatically
```

## Hybrid Source Strategy

The plugin uses a **smart hybrid approach**:

| Scenario | Source | Benefit |
|----------|--------|---------|
| Cache exists | `~/.cache/superpowers/skills` | Single source, upstream updates |
| Cache missing | `.agents/skills/*.SKILL.md` | Works standalone, no dependencies |
| User preference | Explicit symlink | Projects control their skills |

This means:
- ✅ Works without internet after bootstrap
- ✅ Automatic updates when cache updated
- ✅ Single source of truth across projects
- ✅ Portable if cache unavailable
- ✅ Flexible for different workflows

## Troubleshooting

### Plugin Not Finding Skills

```bash
# Check bootstrap
ls ~/.cache/superpowers/skills

# If missing, manually bootstrap
~/.cache/superpowers/plugin/bootstrap-superpowers.sh

# Or clear and let plugin re-bootstrap
rm -rf ~/.cache/superpowers
copilot "any prompt"  # Triggers re-bootstrap
```

### Bundled Skills vs Cache Skills

- **Cache skills** (primary): Updates from obra/superpowers automatically
- **Bundled skills** (fallback): Built into plugin, always available

To force bundled skills:

```bash
export SUPERPOWERS_USE_BUNDLED=1
copilot
```

## For Developers

### Contributing Skills

1. Edit `.agents/skills/*/SKILL.md` in this repository
2. Or contribute directly to [obra/superpowers](https://github.com/obra/superpowers) for shared skills

### Testing Plugin Locally

```bash
# Install from local directory
copilot plugin add ./path/to/vsc-superpowers

# Test bootstrap
copilot "test prompt"
```

### Plugin Development

- Manifest: `.agents/manifest.json`
- Bootstrap: `.agents/bootstrap-superpowers.sh`
- Skills: `.agents/skills/*/SKILL.md`
- Documentation: `docs/PLUGIN_*.md`

## Related Resources

- **Main repo:** [earchibald/vsc-superpowers](https://github.com/earchibald/vsc-superpowers)
- **Upstream:** [obra/superpowers](https://github.com/obra/superpowers)
- **Agent Skills Standard:** [anthropic.com/agents](https://www.anthropic.com/agents)
- **Copilot CLI:** [github.com/github/copilot-cli](https://github.com/github/copilot-cli)

## License

Same as vsc-superpowers repository (see LICENSE)

---

For questions or issues, open an issue on GitHub or check the main repository README.
