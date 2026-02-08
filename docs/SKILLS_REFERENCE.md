# Superpowers Skills Reference

Complete reference for all 14 Superpowers skills available as VS Code slash commands.

## Overview

Superpowers provides a complete software development workflow through composable "skills" that enforce best practices. Each skill is available as a slash command in GitHub Copilot Chat, providing structured guidance for specific development tasks.

All skills follow core principles:
- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing  
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

---

## Core Workflow

### `/write-plan` (writing-plans)

**When to use:** Before starting any multi-step implementation work

**What it does:** Creates comprehensive, bite-sized implementation plans through an interactive interview process. Transforms vague ideas into actionable steps with exact file paths, line numbers, and complete code snippets.

**Key features:**
- Interactive questioning to clarify requirements
- Task decomposition into manageable chunks
- TDD-focused with explicit test requirements
- Complete context (files, line numbers, exact code)
- Human checkpoint boundaries for large tasks
- Saved to `plan.md` for tracking

**Example:** "I need to add user authentication" → 12-step plan with tests, database schema, API endpoints, and UI components.

### `/execute-plan` (executing-plans)

**When to use:** After creating a plan with `/write-plan`, ready to implement

**What it does:** Executes implementation plans with human checkpoints at logical boundaries. Reads `plan.md`, executes tasks in sequence, checks off completed work, and pauses for validation.

**Key features:**
- Batch execution of related tasks
- Progress tracking (✓ completed, ⬜ pending)
- Human validation at checkpoints
- Automatic state persistence
- Resume capability after interruption
- Integration with `/review` and `/verify`

**Example:** Execute a 12-step authentication plan, pausing after: (1) schema migration, (2) API implementation, (3) UI integration.

### `/brainstorm` (brainstorming)

**When to use:** Before any creative work, new feature design, or when exploring solution space

**What it does:** Refines ideas through Socratic dialogue, asking clarifying questions rather than jumping to solutions. Explores alternatives, validates assumptions, and ensures complete understanding before implementation.

**Key features:**
- Question-driven exploration
- Alternative solutions presented
- Tradeoff analysis
- Incremental validation
- Prevents premature optimization
- Captures decisions for future reference

**Example:** "Should we use REST or GraphQL?" → Discussion of use cases, team experience, client needs, tooling, before recommending approach.

---

## Testing & Debugging

### `/tdd` (test-driven-development)

**When to use:** When implementing any feature or bugfix (default mode for all code)

**What it does:** Enforces strict RED-GREEN-REFACTOR cycle. Never writes implementation code without a failing test first.

**Key features:**
- **RED**: Write minimal failing test
- **GREEN**: Write minimal code to pass
- **REFACTOR**: Clean up without changing behavior
- Prevents untested code
- Ensures testability from start
- Builds regression suite incrementally

**Example:** Adding email validation → (1) Write test with invalid email, see failure, (2) Add validation logic, see pass, (3) Extract validator function, all tests still pass.

### `/investigate` (systematic-debugging)

**When to use:** When tests fail, bugs appear, or unexpected behavior occurs

**What it does:** Performs 4-phase root cause analysis instead of ad-hoc guessing. Systematically gathers evidence, forms hypotheses, tests theories, and implements defense-in-depth fixes.

**Key features:**
- **Phase 1: Reproduce** - Create minimal failing case
- **Phase 2: Gather Evidence** - Logs, stack traces, context
- **Phase 3: Form Hypothesis** - Theory about root cause
- **Phase 4: Test & Fix** - Verify theory, implement with tests
- Evidence-based over intuition
- Prevents misdiagnosis
- Adds tests to prevent regression

**Example:** "API sometimes returns 500" → Reproduce with specific input, examine logs showing DB timeout, hypothesize connection pool exhaustion, verify with metrics, fix with pool size increase + timeout handling + monitoring.

### `/verify` (verification-before-completion)

**When to use:** After implementing a fix or feature claim

**What it does:** Ensures fixes actually work before claiming success. Runs tests, checks edge cases, validates in relevant environments.

**Key features:**
- Prevents false positives
- Evidence-based verification
- Tests all affected code paths
- Checks for regressions
- Documents verification steps
- Builds confidence before merge

**Example:** After fixing a race condition → Run tests 100x, test with different thread counts, verify logs show no warnings, check metrics dashboard.

---

## Git Workflows

### `/worktree` (using-git-worktrees)

**When to use:** Starting work on a new feature or fix

**What it does:** Creates an isolated workspace on a new branch using git worktrees. Enables parallel development without switching contexts or stashing changes.

**Key features:**
- Separate directory per branch
- Clean test baseline
- Proper isolation from main work
- No stash/switch overhead
- Multiple tasks in parallel
- Easy cleanup when done

**Example:** Working on feature-A → `/worktree feature-B` creates `../feature-B` directory with new branch, leaving feature-A untouched.

### `/finish-branch` (finishing-a-development-branch)

**When to use:** When all tasks in a branch are complete and verified

**What it does:** Handles the complete merge/PR/keep/discard workflow. Verifies tests pass, presents options, executes chosen action, cleans up worktree.

**Key features:**
- Pre-merge test verification
- Multiple completion strategies:
  - Merge to main + delete branch
  - Create PR for review
  - Keep branch for later
  - Discard changes
- Automatic worktree cleanup
- Commit message guidance

**Example:** After completing feature-B → `/finish-branch` runs tests, asks "merge/PR/keep/discard?", executes choice, removes `../feature-B` directory.

---

## Code Review

### `/review` (requesting-code-review)

**When to use:** Between tasks, before pushing, or when quality checkpoint needed

**What it does:** Performs self-review against plan and code quality standards. Checks for completeness, test coverage, code style, potential bugs.

**Key features:**
- Pre-review checklist
- Plan compliance verification
- Code quality assessment
- Security considerations
- Performance implications
- Severity-based reporting (critical/major/minor)
- Generates structured feedback

**Example:** After implementing 3 tasks → `/review` finds: 1 critical (missing input validation), 2 major (no error handling, untested edge case), 3 minor (unclear variable names).

### `/receive-review` (receiving-code-review)

**When to use:** After receiving code review feedback from humans or automated tools

**What it does:** Responds systematically to review comments with structured approach. Categorizes feedback, prioritizes issues, implements fixes, tracks resolution.

**Key features:**
- Comment categorization
- Priority ordering
- Systematic resolution
- Change tracking
- Response documentation
- Follow-up verification

**Example:** Receive 8 review comments → `/receive-review` organizes: 3 must-fix, 3 should-fix, 2 suggestions → Implements fixes → Documents responses → Verifies all addressed.

---

## Advanced Development

### `/subagent-dev` (subagent-driven-development)

**When to use:** Executing complex plans with many tasks requiring fresh perspective per task

**What it does:** Dispatches a fresh subagent for each task with two-stage review process: (1) spec compliance check, (2) code quality review. Ensures fast iteration with quality gates.

**Key features:**
- Fresh context per task (no baggage)
- Two-stage review:
  1. **Spec check** - Meets requirements?
  2. **Quality check** - Follows best practices?
- Fast iteration cycle
- Automated quality enforcement
- Progress tracking across tasks
- Integrates with plan execution

**Example:** 15-task plan → Subagent 1 implements task 1 → Review pass → Subagent 2 implements task 2 → Review pass → ... → 15 tasks completed with consistent quality.

### `/dispatch-agents` (dispatching-parallel-agents)

**When to use:** When tasks can be parallelized (independent components, different services, concurrent features)

**What it does:** Runs concurrent subagent workflows for independent tasks. Coordinates parallel work, aggregates results, handles conflicts.

**Key features:**
- Parallel task execution
- Agent coordination
- Result aggregation
- Conflict detection
- Progress monitoring
- Success/failure reporting

**Example:** Need to update 4 microservices → `/dispatch-agents` spawns 4 agents, each updates one service → All complete in parallel → Results aggregated → Conflicts resolved → Integration verified.

---

## Meta

### `/write-skill` (writing-skills)

**When to use:** Creating new skills or editing existing Superpowers skills

**What it does:** Applies TDD methodology to skill creation. Write usage scenarios first (tests), implement skill instructions (code), validate with pressure testing (refactor).

**Key features:**
- RED-GREEN-REFACTOR for documentation
- Pressure scenario testing
- Edge case validation
- Clear trigger conditions
- Success criteria definition
- Integration with existing skills

**Example:** Create `/estimate` skill → (1) Write scenarios where estimation needed, (2) Write skill instructions, (3) Test on complex estimation case, (4) Refine based on results.

### `/superpowers` (using-superpowers)

**When to use:** Learning about the system, getting started, or understanding capabilities

**What it does:** Provides introduction to the Superpowers framework, philosophy, and available capabilities. Guides new users through core concepts and workflows.

**Key features:**
- System overview
- Workflow explanation
- Philosophy and principles
- Skill catalog
- Getting started guide
- Best practices

**Example:** New to Superpowers → `/superpowers` explains the 4 phases (brainstorm, plan, execute, verify) and TDD requirement.

---

## Command Mapping

Some skills use different names in VS Code to avoid conflicts with reserved commands.

| Original Skill | VS Code Command | Reason for Rename |
|----------------|-----------------|-------------------|
| writing-plans | `/write-plan` | Avoids VS Code's built-in `/plan` command |
| systematic-debugging | `/investigate` | Avoids VS Code's built-in `/fix` command |
| test-driven-development | `/tdd` | Brevity (shorter is better for frequent use) |
| subagent-driven-development | `/subagent-dev` | Brevity |
| dispatching-parallel-agents | `/dispatch-agents` | Brevity |
| finishing-a-development-branch | `/finish-branch` | Brevity |
| verification-before-completion | `/verify` | Brevity |
| using-git-worktrees | `/worktree` | Brevity |
| requesting-code-review | `/review` | Brevity |
| receiving-code-review | `/receive-review` | Brevity |
| executing-plans | `/execute-plan` | Consistency with singular form |
| writing-skills | `/write-skill` | Consistency with singular form |
| brainstorming | `/brainstorm` | Direct mapping (no conflict) |
| using-superpowers | `/superpowers` | Direct mapping (no conflict) |

### Why Rename Commands?

**Conflict Avoidance:** VS Code reserves certain slash commands (`/plan`, `/fix`, `/explain`, etc.). Using these names would create confusion and prevent our skills from being invoked. The Superpowers installer automatically maps to conflict-free names.

**Brevity:** Shorter commands are faster to type and easier to remember. Since these skills are used frequently throughout development, concise names improve workflow efficiency.

**Consistency:** All commands follow a consistent pattern (verb or verb-noun), making the command set more predictable and easier to learn.

---

## Typical Workflows

### Simple Feature Development
1. `/brainstorm` - Refine idea
2. `/write-plan` - Create implementation plan
3. `/tdd` - Implement with tests
4. `/review` - Self-review
5. `/verify` - Confirm it works

### Complex Multi-Task Project
1. `/brainstorm` - Explore solution space
2. `/write-plan` - Comprehensive plan
3. `/worktree` - Isolated workspace
4. `/execute-plan` - Implement with checkpoints
5. `/review` - Check quality
6. `/verify` - Run full test suite
7. `/finish-branch` - Merge or PR

### Debugging Session
1. `/investigate` - Systematic root cause analysis
2. `/tdd` - Write failing test for bug
3. `/investigate` - Fix with evidence
4. `/verify` - Confirm fix works
5. `/review` - Check for similar issues

### Parallel Development
1. `/write-plan` - Overall architecture
2. `/dispatch-agents` - Parallel implementation
3. `/review` - Check each component
4. `/verify` - Integration testing
5. `/finish-branch` - Merge all work

### Creating New Skills
1. `/write-skill` - Develop new skill
2. `/tdd` - Test with scenarios
3. `/verify` - Validate effectiveness
4. `/review` - Ensure quality

---

## Tips & Best Practices

### Always Start With Planning
Never jump into coding without a plan. Use `/brainstorm` for exploration, then `/write-plan` for structure.

### TDD Is Non-Negotiable
Use `/tdd` for all implementation work. No exceptions. Tests are not "nice to have"—they're required.

### Review Early and Often
Don't wait until the end. Use `/review` between tasks to catch issues while they're fresh.

### Verify Before Claiming Success
Use `/verify` after every fix or feature. Evidence beats assumptions.

### Use Worktrees for Isolation
Start new work with `/worktree` to keep experiments separate from stable code.

### Leverage Subagents for Complex Plans
For plans with 10+ tasks, use `/subagent-dev` to maintain fresh perspective per task.

### Debug Systematically
When things break, resist ad-hoc fixes. Use `/investigate` to find root cause and implement proper solution.

### Finish What You Start
Use `/finish-branch` to properly close out work. Don't leave orphaned branches.

---

## Getting Help

- **Skill details:** Use the slash command itself—each skill includes complete instructions
- **Workflow guidance:** Use `/superpowers` for system overview
- **Debugging installation:** Run `./scripts/verify-installation.sh`
- **Upstream documentation:** Visit [github.com/obra/superpowers](https://github.com/obra/superpowers)

---

## Version Information

This reference documents the 14 core skills from Superpowers v1.x as implemented for VS Code.

Last updated: February 8, 2026
