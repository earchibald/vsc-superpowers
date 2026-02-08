# Prompt Parity Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Achieve full prompt parity with native Superpowers by installing all missing skills as VS Code prompts, maintaining command mappings that avoid VS Code conflicts.

**Architecture:** Extend the existing `install-superpowers.sh` to install all 14 Superpowers skills as VS Code prompts while preserving the /plan → /write-plan and /fix → /investigate mappings that avoid VS Code reserved commands.

**Tech Stack:** Bash scripting, VS Code prompts (.prompt.md files), YAML frontmatter, Markdown

---

## Current State Analysis

### Currently Installed (6/14 skills):
- ✓ brainstorm → `/brainstorm` (brainstorming)
- ✓ investigate → `/investigate` (systematic-debugging) 
- ✓ review → `/review` (requesting-code-review)
- ✓ superpowers → `/superpowers` (using-superpowers)
- ✓ tdd → `/tdd` (test-driven-development)
- ✓ write-plan → `/write-plan` (writing-plans)

### Missing (8/14 skills):
- ✗ dispatching-parallel-agents
- ✗ executing-plans
- ✗ finishing-a-development-branch
- ✗ receiving-code-review
- ✗ subagent-driven-development
- ✗ using-git-worktrees
- ✗ verification-before-completion
- ✗ writing-skills

---

## Task 1: Read All Missing Skills

**Files:**
- Read: `~/.cache/superpowers/skills/dispatching-parallel-agents/SKILL.md`
- Read: `~/.cache/superpowers/skills/executing-plans/SKILL.md`  
- Read: `~/.cache/superpowers/skills/finishing-a-development-branch/SKILL.md`
- Read: `~/.cache/superpowers/skills/receiving-code-review/SKILL.md`
- Read: `~/.cache/superpowers/skills/subagent-driven-development/SKILL.md`
- Read: `~/.cache/superpowers/skills/using-git-worktrees/SKILL.md`
- Read: `~/.cache/superpowers/skills/verification-before-completion/SKILL.md`
- Read: `~/.cache/superpowers/skills/writing-skills/SKILL.md`

**Step 1: Read all 8 missing skill files**

Use parallel reads to gather all skill content:

```bash
for skill in dispatching-parallel-agents executing-plans finishing-a-development-branch \
  receiving-code-review subagent-driven-development using-git-worktrees \
  verification-before-completion writing-skills; do
  echo "=== $skill ===" 
  head -50 ~/.cache/superpowers/skills/$skill/SKILL.md
done
```

**Step 2: Document slash command names**

Create mapping file based on descriptions:
- dispatching-parallel-agents → `/dispatch-agents`
- executing-plans → `/execute-plan`
- finishing-a-development-branch → `/finish-branch`
- receiving-code-review → `/receive-review`
- subagent-driven-development → `/subagent-dev`
- using-git-worktrees → `/worktree`
- verification-before-completion → `/verify`
- writing-skills → `/write-skill`

**Step 3: Verify no conflicts with VS Code**

Check that none of these conflict with VS Code reserved commands (only /plan and /fix are known conflicts).

---

## Task 2: Update Install Script - Add Missing Skills

**Files:**
- Modify: `install-superpowers.sh:33-38`

**Step 1: Expand SKILLS_TO_INSTALL array**

Replace the current array with complete list:

```bash
SKILLS_TO_INSTALL=(
    # Core workflow
    "writing-plans:write-plan:Create a detailed implementation plan (Superpowers)"
    "executing-plans:execute-plan:Execute an implementation plan with checkpoints"
    "brainstorming:brainstorm:Generate creative solutions and explore ideas"
    
    # Testing & Debugging
    "test-driven-development:tdd:Implement code using strict TDD cycles"
    "systematic-debugging:investigate:Perform systematic root-cause analysis"
    "verification-before-completion:verify:Ensure fixes work before claiming success"
    
    # Git Workflows
    "using-git-worktrees:worktree:Create isolated workspace for parallel development"
    "finishing-a-development-branch:finish-branch:Merge, PR, or discard completed work"
    
    # Code Review
    "requesting-code-review:review:Request a self-correction code review"
    "receiving-code-review:receive-review:Respond to code review feedback"
    
    # Advanced Development
    "subagent-driven-development:subagent-dev:Dispatch subagents for task-by-task development"
    "dispatching-parallel-agents:dispatch-agents:Run concurrent subagent workflows"
    
    # Meta
    "writing-skills:write-skill:Create new skills following TDD best practices"
    "using-superpowers:superpowers:Learn about the Superpowers capabilities"
)
```

**Step 2: Run test to verify syntax**

```bash
bash -n install-superpowers.sh
```

Expected: No output (success)

**Step 3: Commit**

```bash
git add install-superpowers.sh
git commit -m "feat: add all 14 superpowers skills to installer"
```

---

## Task 3: Run Installer to Generate Prompts

**Files:**
- Execute: `install-superpowers.sh`
- Generated: `.github/prompts/execute-plan.prompt.md`
- Generated: `.github/prompts/verify.prompt.md`
- Generated: `.github/prompts/worktree.prompt.md`
- Generated: `.github/prompts/finish-branch.prompt.md`
- Generated: `.github/prompts/receive-review.prompt.md`
- Generated: `.github/prompts/subagent-dev.prompt.md`
- Generated: `.github/prompts/dispatch-agents.prompt.md`
- Generated: `.github/prompts/write-skill.prompt.md`

**Step 1: Run installer**

```bash
cd /Users/earchibald/work/vsc-superpowers
./install-superpowers.sh
```

Expected output:
```
🦸 Superpowers Installer & Updater
==================================
🔄 Updating Superpowers cache...
⚡ Updating existing Superpowers kernel...
🛠️  Installing Skills as Prompts...
   -> Installing /write-plan (Create a detailed implementation plan)
   -> Installing /execute-plan (Execute an implementation plan with checkpoints)
   ...
   -> Installing /write-skill (Create new skills following TDD best practices)
🎉 Done! Superpowers is active.
```

**Step 2: Verify generated files**

```bash
ls -la .github/prompts/
```

Expected: 14 .prompt.md files present

**Step 3: Check one generated file structure**

```bash
head -20 .github/prompts/execute-plan.prompt.md
```

Expected: YAML frontmatter + skill content

**Step 4: Commit new prompt files**

```bash
git add .github/prompts/*.prompt.md
git commit -m "feat: generate all 14 superpowers prompt files"
```

---

## Task 4: Update Copilot Instructions - Document All Skills

**Files:**
- Modify: `.github/copilot-instructions.md:12-20`

**Step 1: Expand skills list in copilot instructions**

Update the kernel to mention all important skills:

```markdown
## YOUR SKILLS (Slash Commands)
VS Code reserved commands are replaced with these Superpowers equivalents:

**Core Workflow:**
- **Use `/write-plan`** (instead of /plan) to interview me and build a detailed implementation plan.
- **Use `/execute-plan`** to execute the plan with human checkpoints.
- **Use `/brainstorm`** before any creative work to refine requirements through dialogue.

**Testing & Debugging:**
- **Use `/tdd`** to write code. NEVER write code without a failing test first.
- **Use `/investigate`** (instead of /fix) when tests fail to run systematic root-cause analysis.
- **Use `/verify`** to ensure fixes actually work before claiming success.

**Git Workflows:**
- **Use `/worktree`** to create isolated workspaces for parallel development.
- **Use `/finish-branch`** when work is complete to merge, create PR, or discard changes.

**Code Review:**
- **Use `/review`** between tasks to catch issues early.
- **Use `/receive-review`** to respond systematically to code review feedback.

**Advanced:**
- **Use `/subagent-dev`** for task-by-task development with automated reviews.
- **Use `/dispatch-agents`** for concurrent subagent workflows.
- **Use `/write-skill`** to create new skills following TDD methodology.
- **Use `/superpowers`** to learn about all capabilities.
```

**Step 2: Test syntax**

```bash
cat .github/copilot-instructions.md | grep -c "^- \*\*Use"
```

Expected: Count should be 14 (one for each skill)

**Step 3: Commit**

```bash
git add .github/copilot-instructions.md
git commit -m "docs: expand copilot instructions with all 14 skills"
```

---

## Task 5: Create Verification Script

**Files:**
- Create: `scripts/verify-installation.sh`

**Step 1: Write verification script**

```bash
#!/usr/bin/env bash
set -e

echo "🔍 Verifying Superpowers Installation"
echo "======================================"

# Check cache exists
if [ ! -d ~/.cache/superpowers ]; then
    echo "❌ Cache not found at ~/.cache/superpowers"
    exit 1
fi
echo "✓ Cache found"

# Check .github structure
if [ ! -f .github/copilot-instructions.md ]; then
    echo "❌ copilot-instructions.md not found"
    exit 1
fi
echo "✓ Instructions file found"

# Check all 14 prompts exist
EXPECTED_PROMPTS=(
    "brainstorm" "write-plan" "execute-plan" "tdd" "investigate" "verify" 
    "worktree" "finish-branch" "review" "receive-review" "subagent-dev" 
    "dispatch-agents" "write-skill" "superpowers"
)

MISSING_COUNT=0
for prompt in "${EXPECTED_PROMPTS[@]}"; do
    if [ ! -f ".github/prompts/$prompt.prompt.md" ]; then
        echo "❌ Missing: $prompt.prompt.md"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done

if [ $MISSING_COUNT -eq 0 ]; then
    echo "✓ All 14 prompts installed"
else
    echo "❌ Missing $MISSING_COUNT prompts"
    exit 1
fi

# Verify frontmatter in a sample file
if ! grep -q "^name: write-plan$" .github/prompts/write-plan.prompt.md; then
    echo "❌ Frontmatter validation failed"
    exit 1
fi
echo "✓ Frontmatter format valid"

echo ""
echo "✅ Installation verified successfully!"
echo "📢 Reload VS Code (Developer: Reload Window) to activate."
```

**Step 2: Make executable**

```bash
chmod +x scripts/verify-installation.sh
```

**Step 3: Run verification**

```bash
./scripts/verify-installation.sh
```

Expected:
```
🔍 Verifying Superpowers Installation
======================================
✓ Cache found
✓ Instructions file found
✓ All 14 prompts installed
✓ Frontmatter format valid

✅ Installation verified successfully!
📢 Reload VS Code (Developer: Reload Window) to activate.
```

**Step 4: Commit verification script**

```bash
git add scripts/verify-installation.sh
git commit -m "feat: add installation verification script"
```

---

## Task 6: Create Documentation

**Files:**
- Create: `docs/SKILLS_REFERENCE.md`

**Step 1: Write skills reference**

```markdown
# Superpowers Skills Reference

Complete list of all 14 Superpowers skills available in VS Code.

## Core Workflow

### `/write-plan` (writing-plans)
**When to use:** Before starting multi-step implementation work  
**What it does:** Creates comprehensive, bite-sized implementation plans  
**Key features:** Exact file paths, complete code snippets, TDD-focused

### `/execute-plan` (executing-plans)
**When to use:** After creating a plan, ready to implement  
**What it does:** Executes plans with human checkpoints at logical boundaries  
**Key features:** Batch execution, progress tracking, human validation

### `/brainstorm` (brainstorming)
**When to use:** Before any creative work or new feature design  
**What it does:** Refines ideas through Socratic dialogue  
**Key features:** Question-driven, explores alternatives, validates incrementally

## Testing & Debugging

### `/tdd` (test-driven-development)
**When to use:** When implementing any feature or bugfix  
**What it does:** Enforces RED-GREEN-REFACTOR cycle  
**Key features:** Write test first, watch fail, minimal code, watch pass

### `/investigate` (systematic-debugging)
**When to use:** When tests fail or bugs appear  
**What it does:** 4-phase root cause analysis  
**Key features:** Systematic over ad-hoc, evidence-based, defense-in-depth

### `/verify` (verification-before-completion)
**When to use:** After implementing a fix  
**What it does:** Ensures fixes actually work before claiming success  
**Key features:** Evidence-based verification, prevents false positives

## Git Workflows

### `/worktree` (using-git-worktrees)
**When to use:** Starting work on a new feature or fix  
**What it does:** Creates isolated workspace on new branch  
**Key features:** Parallel development, clean test baseline, proper isolation

### `/finish-branch` (finishing-a-development-branch)
**When to use:** When all tasks in a branch are complete  
**What it does:** Handles merge/PR/keep/discard workflow  
**Key features:** Verifies tests, presents options, cleans up worktree

## Code Review

### `/review` (requesting-code-review)
**When to use:** Between tasks, before pushing  
**What it does:** Self-review against plan and code quality  
**Key features:** Pre-review checklist, severity-based reporting

### `/receive-review` (receiving-code-review)
**When to use:** After receiving review feedback  
**What it does:** Systematic response to review comments  
**Key features:** Structured approach, tracks resolutions

## Advanced Development

### `/subagent-dev` (subagent-driven-development)
**When to use:** Executing complex plans with many tasks  
**What it does:** Dispatches fresh subagent per task with two-stage review  
**Key features:** Fast iteration, spec compliance check, code quality review

### `/dispatch-agents` (dispatching-parallel-agents)
**When to use:** When tasks can be parallelized  
**What it does:** Runs concurrent subagent workflows  
**Key features:** Parallel execution, coordination, result aggregation

## Meta

### `/write-skill` (writing-skills)
**When to use:** Creating new skills or editing existing skills  
**What it does:** Applies TDD methodology to skill creation  
**Key features:** RED-GREEN-REFACTOR for docs, pressure scenarios, validation

### `/superpowers` (using-superpowers)
**When to use:** Learning about the system or getting started  
**What it does:** Introduction to the Superpowers framework  
**Key features:** Overview, workflow, philosophy

---

## Command Mapping

Note: Some skills are renamed to avoid VS Code reserved commands:

| Original Skill | VS Code Command | Reason |
|----------------|-----------------|--------|
| writing-plans | `/write-plan` | Avoids VS Code's `/plan` |
| systematic-debugging | `/investigate` | Avoids VS Code's `/fix` |
| subagent-driven-development | `/subagent-dev` | Brevity |
| dispatching-parallel-agents | `/dispatch-agents` | Brevity |
| finishing-a-development-branch | `/finish-branch` | Brevity |
| verification-before-completion | `/verify` | Brevity |
| writing-skills | `/write-skill` | Brevity |
```

**Step 2: Commit documentation**

```bash
git add docs/SKILLS_REFERENCE.md
git commit -m "docs: add comprehensive skills reference"
```

---

## Task 7: Update README

**Files:**
- Modify: `README.md` (create if doesn't exist)

**Step 1: Write README**

```markdown
# VS Code Superpowers

An implementation of the [Superpowers](https://github.com/obra/superpowers) framework for GitHub Copilot in VS Code, providing all 14 core skills as native slash commands.

## What is Superpowers?

Superpowers is a complete software development workflow for coding agents, built on a set of composable "skills" that enforce best practices like TDD, systematic debugging, and comprehensive planning.

## Installation

```bash
# Clone this repository
git clone https://github.com/yourusername/vsc-superpowers.git
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
```

**Step 2: Commit README**

```bash
git add README.md
git commit -m "docs: create comprehensive README"
```

---

## Task 8: Test Full Installation Flow

**Files:**
- Test: Complete installation in fresh directory

**Step 1: Create test directory**

```bash
cd /tmp
mkdir superpowers-test
cd superpowers-test
git init
```

**Step 2: Copy installer**

```bash
cp /Users/earchibald/work/vsc-superpowers/install-superpowers.sh .
```

**Step 3: Run installer**

```bash
./install-superpowers.sh
```

Expected: 
- Cache created at ~/.cache/superpowers
- .github/copilot-instructions.md created
- .github/prompts/ created with 14 files

**Step 4: Verify all prompts**

```bash
ls -1 .github/prompts/ | wc -l
```

Expected: 14

**Step 5: Check a prompt**

```bash
cat .github/prompts/subagent-dev.prompt.md | head -20
```

Expected: Valid YAML frontmatter + skill content

**Step 6: Clean up test directory**

```bash
cd /Users/earchibald/work/vsc-superpowers
rm -rf /tmp/superpowers-test
```

**Step 7: Document test results**

Create `docs/TESTING.md` documenting the test procedure and results.

---

## Task 9: Create LICENSE File

**Files:**
- Create: `LICENSE`

**Step 1: Create MIT License**

```text
MIT License

Copyright (c) 2026 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

This project bundles skills from https://github.com/obra/superpowers
which is also MIT licensed.
```

**Step 2: Commit license**

```bash
git add LICENSE
git commit -m "docs: add MIT license"
```

---

## Task 10: Final Verification & Documentation

**Files:**
- Create: `docs/TESTING.md`
- Update: All documentation finalized

**Step 1: Run final verification**

```bash
./scripts/verify-installation.sh
```

Expected: All checks pass

**Step 2: Test one command in VS Code**

1. Reload VS Code
2. Open Copilot chat
3. Type `/write-plan`
4. Verify prompt appears in autocomplete

**Step 3: Document testing procedure**

Create `docs/TESTING.md`:

```markdown
# Testing Guide

## Automated Tests

### Installation Verification

```bash
./scripts/verify-installation.sh
```

Checks:
- Cache exists at ~/.cache/superpowers  - Instructions file present
- All 14 prompts installed
- Frontmatter format valid

## Manual Tests

### Test Prompt Availability

1. Reload VS Code (Cmd+Shift+P > Developer: Reload Window)
2. Open Copilot Chat
3. Type `/` to see command list
4. Verify all 14 superpowers commands appear:
   - /brainstorm
   - /write-plan
   - /execute-plan
   - /tdd
   - /investigate
   - /verify
   - /worktree
   - /finish-branch
   - /review
   - /receive-review
   - /subagent-dev
   - /dispatch-agents
   - /write-skill
   - /superpowers

### Test Skill Invocation

1. Type `/write-plan`
2. Press Enter
3. Verify skill content loads
4. Check for proper frontmatter and instructions

### Test Update Flow

1. Run `./install-superpowers.sh` again
2. Verify idempotent behavior
3. Check logs show "Updating" not "Installing"
4. Verify no file duplication

## Integration Tests

### End-to-End Workflow

1. Use `/brainstorm` to design a feature
2. Use `/write-plan` to create implementation plan
3. Use `/worktree` to create isolated workspace
4. Use `/tdd` to implement first task
5. Use `/review` to check work
6. Use `/verify` to ensure tests pass
7. Use `/finish-branch` to complete workflow

## Troubleshooting

### Prompts Not Appearing

- Verify reload: Cmd+Shift+P > Developer: Reload Window
- Check file exists: `ls .github/prompts/`
- Verify frontmatter: `head .github/prompts/write-plan.prompt.md`

### Cache Not Updating

- Manual update: `cd ~/.cache/superpowers && git pull`
- Check network: `ping github.com`

### Incorrect Behavior

- Check instructions: `cat .github/copilot-instructions.md`
- Verify SUPERPOWERS-START/END tags present
- Re-run installer: `./install-superpowers.sh`
```

**Step 4: Commit testing docs**

```bash
git add docs/TESTING.md
git commit -m "docs: add comprehensive testing guide"
```

**Step 5: Create final summary**

Generate final commit:

```bash
git log --oneline | head -15
```

Expected to see all commits from this plan.

---

## Completion Checklist

- [ ] All 14 skills added to installer configuration
- [ ] Installer generates 14 prompt files correctly
- [ ] Copilot instructions document all skills
- [ ] Verification script passes all checks
- [ ] Documentation complete (README, SKILLS_REFERENCE, TESTING)
- [ ] License file created
- [ ] Manual testing in VS Code successful
- [ ] All commits made with clear messages

---

## Post-Implementation

After completing this plan, users will have:

1. **Full Prompt Parity**: All 14 Superpowers skills available as VS Code slash commands
2. **Conflict-Free**: No conflicts with VS Code reserved commands (/plan, /fix)
3. **Easy Installation**: Single script installs everything
4. **Verification**: Automated script confirms correct installation
5. **Documentation**: Complete reference for all skills and workflows

The system will function as a complete "operating system" for GitHub Copilot, enforcing best practices through automated skill triggering.
