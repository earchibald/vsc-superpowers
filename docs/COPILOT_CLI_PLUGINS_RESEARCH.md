# Research: Copilot CLI Plugin & Skills Integration for Superpowers

## TL;DR

**Three major new features in Copilot CLI v0.0.406 enable a new integration path for vsc-superpowers:**

1. **Plugin-to-Skills Translation** (v0.0.406): Plugins can now export commands as "Agent Skills"
2. **Plugin Marketplace URLs** (v0.0.406): Install plugins directly from URLs (not just official marketplace)
3. **Plugin Skills in Prompt Mode** (v0.0.403): Plugin skills work in non-interactive CLI (`copilot -p "..."`)

**Impact:** Superpowers can become a **Copilot CLI plugin** with skills automatically available in both interactive and non-interactive modes.

---

## What Each Feature Means

### 1. Commands from Plugins are Translated into Skills (v0.0.406)

**What it is:**
- Plugins can now export their commands as "Agent Skills"
- These become discoverable skills that Copilot automatically uses when relevant
- Solves the UX problem: users don't need to manually invoke `/write-plan`, they can just say "create an implementation plan"

**Example:**
```
Old way:  /write-plan → Interactive skill invocation
New way:  plugin command → Translated to agent skill → Copilot uses automatically
```

**Technical:**
- Plugins define commands (like shell commands wrapped in JavaScript)
- CLI translates these into Agent Skill format (SKILL.md with YAML frontmatter)
- Copilot CLI recognizes these skills and includes them in context

### 2. Plugin Marketplace Add Accepts URLs (v0.0.406)

**What it is:**
- Instead of only installing official plugins from the marketplace
- Users can now install plugins from ANY URL pointing to a plugin repository
- Enables community plugins and private/custom plugins

**Command syntax:**
```bash
copilot plugin marketplace add https://github.com/user/my-plugin
# or
copilot plugin marketplace add https://github.com/earchibald/superpowers-plugin
```

**Impact:**
- No need to wait for official GitHub marketplace approval
- Users can install superpowers-plugin directly from GitHub
- Enables rapid iteration and experimentation

### 3. Plugin Skills Work in Prompt Mode (v0.0.403)

**What it is:**
- Previously: Plugin skills only worked in interactive mode
- Now: Plugin skills work in both interactive AND non-interactive modes
- Non-interactive mode: `copilot -p "prompt"` (what we use in CI/CD, scripts)

**Impact:**
- Plugin-based Superpowers skills usable in terminal scripts
- Integration with CI/CD pipelines becomes viable
- Automation and headless workflows now supported

---

## How This Enables Superpowers as a Plugin

### Current State (vsc-superpowers)
```
VS Code Copilot Chat
├── Reads `.github/copilot-instructions.md`
├── Reads `.github/prompts/*.prompt.md`
└── Provides 14 slash commands (/write-plan, /tdd, etc.)

Copilot CLI
├── Reads `.github/copilot-instructions.md`
├── Understands project context
└── But: No slash commands, uses text prompts instead
```

### Future State (superpowers-plugin)
```
Plugin Package (npm or GitHub release)
├── Exports 14 commands:
│   ├── write-plan
│   ├── execute-plan
│   ├── tdd
│   └── ... (11 more)
│
└── Plugin CLI translates commands → Agent Skills
    ├── write-plan-skill (SKILL.md)
    ├── execute-plan-skill (SKILL.md)
    ├── tdd-skill (SKILL.md)
    └── ... (11 more)

Installation:
  copilot plugin marketplace add https://github.com/earchibald/superpowers-plugin
  
Usage (Interactive):
  copilot
  > I need to create an implementation plan
  [Copilot loads write-plan-skill and helps]
  
Usage (Non-interactive):
  copilot -p "Create an implementation plan for X" --allow-all
```

---

## Technical Details: Plugin Structure

### What a Plugin Contains

```
superpowers-plugin/
├── manifest.json          # Plugin definition (name, version, commands)
├── index.js              # Main plugin file (exports commands)
├── commands/
│   ├── write-plan.js
│   ├── execute-plan.js
│   ├── tdd.js
│   └── ... (11 more)
├── skills/               # Agent Skills (SKILL.md files)
│   ├── write-plan/
│   │   └── SKILL.md
│   ├── execute-plan/
│   │   └── SKILL.md
│   └── ... (11 more)
└── README.md
```

### manifest.json Example
```json
{
  "name": "superpowers",
  "version": "1.0.0",
  "description": "Agent workflows for structured development",
  "commands": [
    {
      "name": "write-plan",
      "description": "Create detailed implementation plans",
      "handler": "commands/write-plan.js"
    }
    // ... 13 more
  ]
}
```

### Commands → Skills Translation

When CLI loads the plugin:
1. It reads `manifest.json` - sees 14 commands
2. For each command, it looks for corresponding skill definition
3. Translates command description + implementation → `SKILL.md` format
4. Agent Skills are now available to Copilot

---

## Agent Skills Format

### What are Agent Skills?

**Definition:** Folders of instructions, scripts, and resources that Copilot loads when relevant.

**Standard locations:**
- Project-level: `.github/skills/`, `.claude/skills/`
- Personal: `~/.copilot/skills/`, `~/.claude/skills/`
- **Plugin-level**: NEW - plugins can provide skills

**SKILL.md Format:**
```markdown
---
name: write-plan
description: Create detailed implementation plans with exact file paths and code
license: MIT
---

# Write Implementation Plan

## Overview
Create comprehensive, bite-sized implementation plans...

## When to Use
- After design approval, before implementation
- Executing complex multi-step work

## Process
1. Interview about project context
2. Create task breakdown...
```

### How Copilot Uses Skills

1. User provides prompt
2. Copilot analyzes prompt and available skills
3. If a skill is relevant, Copilot loads its SKILL.md
4. SKILL.md content is injected into context
5. Copilot follows the skill's instructions

**Example:**
```
User: "Create an implementation plan for user authentication"
     ↓
Copilot: "The 'write-plan' skill is relevant here"
     ↓
Copilot loads write-plan-skill/SKILL.md
     ↓
Copilot follows the skill's guidance:
"1. Interview..."
"2. Create task breakdown..."
```

---

## Comparison: Current vs Plugin Approach

| Aspect | Current (vsc-superpowers) | Plugin Approach |
|--------|---------------------------|-----------------|
| **Installation** | Clone repo, run installer | `copilot plugin marketplace add URL` |
| **Config management** | Manual symlinks | Plugin handles dependencies |
| **Skills discovery** | Manual slash commands | Automatic (Copilot analyzes request) |
| **VS Code support** | Slash commands ✅ | Via plugins (future) |
| **CLI interactive** | Text prompts only | Skills automatically available |
| **CLI non-interactive** | No skill support | Skills fully supported |
| **Sharing** | Documentation + scripts | Official plugin distribution |
| **Updates** | Manual git pull | `copilot plugin update` |
| **Multi-agent** | Manual context | Automatic skill injection |

---

## Implementation Path

### Phase 1: Validate Plugin Approach (1-2 weeks)
- [ ] Study Copilot CLI plugin API documentation
- [ ] Create minimal plugin with 1 skill (write-plan)
- [ ] Test: Interactive mode
- [ ] Test: Non-interactive mode (`copilot -p "..."`)
- [ ] Verify skill auto-loading

### Phase 2: Convert Superpowers to Plugin (2-3 weeks)
- [ ] Create plugin manifest.json
- [ ] Convert 14 prompt files → 14 commands
- [ ] Create skill definitions for each command
- [ ] Package as npm module / GitHub release

### Phase 3: Packaging & Distribution (1 week)
- [ ] Publish to npm: `@superpowers/copilot-cli-plugin`
- [ ] Create installation guide
- [ ] Add to plugin marketplace (or distribute via URL)

### Phase 4: Documentation & UX Improvements (1-2 weeks)
- [ ] Update README with plugin installation
- [ ] Add plugin-specific workflow examples
- [ ] Create troubleshooting guide

---

## Opportunities & Advantages

### 1. Better UX for Copilot CLI Users
- **Today:** Must know skill names and types prompts describing them
- **Future:** Copilot automatically offers relevant skills

**Example:**
```
Today:
  $ copilot -p "I have a bug, help me debug"
  [Generic debugging advice]

Future (with plugin):
  $ copilot -p "I have a bug, help me debug"
  [Copilot auto-loads /investigate skill]
  [Systematic 4-phase debugging process applied]
```

### 2. Cross-Platform Consistency
- Same skills work in:
  - VS Code Chat (vsc-superpowers)
  - Copilot CLI (via plugin)
  - Gemini CLI (via gemini-superpowers)
  - Any other agent that supports Agent Skills standard

### 3. Community Distribution
- Plugin marketplace enables community to find Superpowers
- URL-based installation allows rapid experimentation
- Official vetting + community-driven innovation

### 4. Multi-Agent Support
- **Current:** Each platform reimplements Superpowers separately
- **Future:** Superpowers plugin works across all platforms supporting Agent Skills

### 5. Automation & CI/CD Integration
- Plugin skills work in non-interactive mode
- Enables Superpowers in CI/CD pipelines
- Automation scripts can use structured workflows

---

## Challenges & Considerations

### 1. Plugin API Stability
- **Risk:** Copilot CLI plugin API is still evolving (v0.0.406)
- **Mitigation:** Start with experimental features flag, work with GitHub on stability

### 2. Skill Context Window Management
- **Risk:** Large skill definitions consume token budget
- **Opportunity:** Optimize skill descriptions for CLI's efficient context use

### 3. Command vs Text Prompt UX
- **Gap:** Slash commands (`/write-plan`) vs text prompts feel different
- **Solution:** Teach users to mention skill names in prompts

### 4. Backward Compatibility
- **Concern:** Existing vsc-superpowers users rely on slash commands
- **Plan:** Maintain vsc-superpowers AND create plugin (not replacement)

---

## Research Questions to Answer

1. **Plugin API Documentation:** Where is the official plugin developer guide?
2. **Skill Translation:** How exactly does CLI translate plugin commands → skills?
3. **Distribution:** What platforms support plugin installation beyond copilot CLI?
4. **Versioning:** How do plugin dependencies and versions work?
5. **Testing:** How to test plugin skills locally before distribution?

### Recommended Next Steps

1. **Immediate:** Review Copilot CLI plugin developer documentation
2. **Week 1:** Create proof-of-concept: minimal plugin with write-plan skill
3. **Week 2:** Test in interactive and non-interactive modes
4. **Week 3:** Validate approach with GitHub Copilot team (community discussions)
5. **Month 2:** Convert full Superpowers to plugin format

---

## Reading List

- [About Agent Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [About Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli)
- [Agent Skills Standard](https://github.com/agentskills/agentskills)
- [Copilot CLI Releases](https://github.com/github/copilot-cli/releases)
- [GitHub Community Discussions](https://github.com/orgs/community/discussions)

---

## Conclusion

The new plugin features in Copilot CLI v0.0.406 create a clear path for Superpowers to become a **first-class plugin** that works consistently across platforms.

**Key advantage:** Users install once (`copilot plugin marketplace add [url]`) and automatically get Superpowers as auto-discovered Agent Skills that work in all modes.

**Status:** Ready for research spike on plugin API and proof-of-concept implementation.
