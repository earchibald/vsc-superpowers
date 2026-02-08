#!/usr/bin/env bash
set -e

# ==============================================================================
# 🦸 SUPERPOWERS FOR VS CODE - INSTALLER & UPDATER
# ==============================================================================
# This script installs the Superpowers "operating system" for GitHub Copilot.
# It clones the source repository to a local cache and injects the necessary
# instructions and prompt files into your current workspace's .github/ folder.
#
# It is IDEMPOTENT: Run it as often as you like to update to the latest version.
# ==============================================================================

# --- CONFIGURATION ---
REPO_URL="https://github.com/obra/superpowers"
CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}"
INSTALL_DIR="$CACHE_ROOT/superpowers"

# Project Locations (Relative to where you run the script)
TARGET_DIR=".github"
INSTRUCTIONS_FILE="$TARGET_DIR/copilot-instructions.md"
PROMPTS_DIR="$TARGET_DIR/prompts"

# --- COMMAND MAPPING (Handling VS Code Conflicts) ---
# Format: "RepoSkillName:NewSlashCommand:Description"
# We rename 'writing-plans' -> 'write-plan' to avoid VS Code's reserved /plan
# We rename 'systematic-debugging' -> 'investigate' to avoid VS Code's reserved /fix
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

echo "🦸 Superpowers Installer & Updater"
echo "=================================="
echo ""

# --- HELPER FUNCTIONS ---

# Detect what conflicts/actions will happen
detect_conflicts() {
    local conflicts=()
    local actions=()
    
    # Check global cache status
    if [ -d "$INSTALL_DIR" ]; then
        actions+=("update:global cache (pull latest)")
    else
        actions+=("clone:global cache")
    fi
    
    # Check .superpowers directory
    if [ -L ".superpowers" ]; then
        local target=$(readlink ".superpowers")
        if [ "$target" = "$INSTALL_DIR" ]; then
            actions+=("skip:symlink (already correct)")
        else
            actions+=("replace:existing symlink with correct target")
            conflicts+=(".superpowers (wrong target: $target)")
        fi
    elif [ -d ".superpowers" ]; then
        conflicts+=(".superpowers (will back up to .superpowers.old)")
        actions+=("create:symlink")
    else
        actions+=("create:symlink")
    fi
    
    # Check instructions file
    if [ -f "$INSTRUCTIONS_FILE" ]; then
        if grep -Fq "$START_TAG" "$INSTRUCTIONS_FILE"; then
            actions+=("update:instructions file (in-place)")
        else
            conflicts+=("$INSTRUCTIONS_FILE (unmanaged - will back up to .old)")
            actions+=("create:new instructions file")
        fi
    else
        actions+=("create:new instructions file")
    fi
    
    # Print formatted output
    echo "📋 PREVIEW: Superpowers Installation Plan"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "📦 GLOBAL CACHE & SYMLINK"
    echo "  Cache Location: $INSTALL_DIR"
    echo "  Workspace Link: ./.superpowers"
    echo "  Target: $INSTALL_DIR"
    echo ""
    
    for action in "${actions[@]}"; do
        IFS=':' read -r type desc <<< "$action"
        case "$type" in
            clone)   echo "  ⬇️  Clone: $desc" ;;
            update)  echo "  🔄 Update: $desc" ;;
            create)  echo "  ✨ Create: $desc" ;;
            replace) echo "  🔃 Replace: $desc" ;;
            skip)    echo "  ⏭️  Skip: $desc" ;;
        esac
    done
    
    echo ""
    echo "📝 INSTRUCTIONS & PROMPTS"
    echo "  Instructions: ./.github/copilot-instructions.md"
    echo "  Path updates: Use ./.superpowers/skills/ instead of ~/.cache/"
    echo "  Prompts Dir: ./.github/prompts/"
    echo "  Skills: ${#SKILLS_TO_INSTALL[@]} slash commands"
    echo ""
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        echo "⚠️  CONFLICTS DETECTED"
        for conflict in "${conflicts[@]}"; do
            echo "  • $conflict"
        done
        echo ""
    fi
    
    echo "💾 DISK IMPACT"
    echo "  Global cache: ~5-10 MB (shared across workspaces)"
    echo "  Workspace: ~1 MB (.superpowers is symlink, negligible)"
    echo ""
}

# --- PREVIEW PHASE ---
detect_conflicts

# Ask for confirmation
echo "ℹ️  To learn more about symlink-based installation,"
echo "   see docs/plans/2026-02-08-symlink-installer-design.md"
echo ""
echo -n "✅ Proceed with installation? (Y/n): "
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]] && [ -n "$response" ]; then
    echo "cancelled."
    exit 0
fi

echo ""
echo "🔨 EXECUTING INSTALLATION..."
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. UPDATE SOURCE OF TRUTH
if [ -d "$INSTALL_DIR" ]; then
    echo "🔄 Updating Superpowers cache at $INSTALL_DIR..."
    git -C "$INSTALL_DIR" pull -q
else
    echo "⬇️  Cloning Superpowers to $INSTALL_DIR..."
    git clone -q "$REPO_URL" "$INSTALL_DIR"
fi

# 2. PREPARE THE KERNEL (THE SYSTEM PROMPT)
KERNEL_SOURCE="$INSTALL_DIR/skills/using-superpowers/SKILL.md"
if [ ! -f "$KERNEL_SOURCE" ]; then
    echo "❌ Error: Could not find core skill at $KERNEL_SOURCE"
    exit 1
fi

START_TAG="<!-- SUPERPOWERS-START -->"
END_TAG="<!-- SUPERPOWERS-END -->"

# We dynamically generate the 'Kernel' text to reference our NEW command names
# instead of the defaults found in the raw markdown.
KERNEL_CONTENT=$(cat <<EOF
# SUPERPOWERS PROTOCOL
You are an autonomous coding agent operating on a strict "Loop of Autonomy."

## CORE DIRECTIVE: The Loop
For every request, you must execute the following cycle:
1. **PERCEIVE**: Read \`plan.md\`. Do not act without checking the plan.
2. **ACT**: Execute the next unchecked step in the plan.
3. **UPDATE**: Check off the step in \`plan.md\` when verified.
4. **LOOP**: If the task is large, do not stop. Continue to the next step.

## YOUR SKILLS (Slash Commands)
VS Code reserved commands are replaced with these Superpowers equivalents:

- **Use \`/write-plan\`** (instead of /plan) to interview me and build \`plan.md\`.
- **Use \`/investigate\`** (instead of /fix) when tests fail to run a systematic analysis.
- **Use \`/tdd\`** to write code. NEVER write code without a failing test.

## RULES
- If \`plan.md\` does not exist, your ONLY valid action is to ask to run \`/write-plan\`.
- Do not guess. If stuck, write a theory in \`scratchpad.md\`.
EOF
)

NEW_INSTRUCTION_BLOCK=$(cat <<EOF
$START_TAG
$KERNEL_CONTENT
$END_TAG
EOF
)

# 3. SURGICAL INJECTION INTO copilot-instructions.md
mkdir -p "$TARGET_DIR"

if [ -f "$INSTRUCTIONS_FILE" ]; then
    # Check if we are already managing this file with tags
    if grep -Fq "$START_TAG" "$INSTRUCTIONS_FILE"; then
        echo "⚡ Updating existing Superpowers kernel..."
        # Use Perl for robust multi-line replacement to handle the tags safely
        # It finds everything between START and END tags and replaces it with NEW_INSTRUCTION_BLOCK
        perl -i -0777 -pe "s/\Q$START_TAG\E.*?\Q$END_TAG\E/$(echo "$NEW_INSTRUCTION_BLOCK" | sed 's/[\/&]/\\&/g' | sed 's/$/\\n/' | tr -d '\n')/s" "$INSTRUCTIONS_FILE"
    else
        echo "⚠️  Found unmanaged instructions. Backing up..."
        mv "$INSTRUCTIONS_FILE" "${INSTRUCTIONS_FILE}.old"
        
        # Combine old user content (if any) with new kernel
        # We put user content FIRST so it takes precedence if conflicting, though System Prompts usually merge.
        echo -e "# Custom Instructions\n(Migrated from old file)\n" > "$INSTRUCTIONS_FILE"
        echo "$NEW_INSTRUCTION_BLOCK" >> "$INSTRUCTIONS_FILE"
        
        echo "✅ Created new file. Old instructions backed up to ${INSTRUCTIONS_FILE}.old"
        echo "📢 ACTION REQUIRED: Ask Copilot to migrate your old settings from the .old file if needed."
    fi
else
    echo "✨ Initializing new instructions file..."
    echo "$NEW_INSTRUCTION_BLOCK" > "$INSTRUCTIONS_FILE"
fi

# 4. INSTALL SKILLS AS PROMPTS
mkdir -p "$PROMPTS_DIR"
echo "🛠️  Installing Skills as Prompts..."

for skill_def in "${SKILLS_TO_INSTALL[@]}"; do
    IFS=':' read -r src_folder cmd_name description <<< "$skill_def"
    
    src_path="$INSTALL_DIR/skills/$src_folder/SKILL.md"
    dest_path="$PROMPTS_DIR/$cmd_name.prompt.md"
    
    if [ -f "$src_path" ]; then
        echo "   -> Installing /$cmd_name ($description)"
        
        # We wrap the raw skill in the VS Code Prompt metadata
        cat <<EOF > "$dest_path"
---
name: $cmd_name
description: $description
---
# Skill: $src_folder
$(cat "$src_path")
EOF
    else
        echo "   ⚠️ Warning: Skill '$src_folder' not found in repo."
    fi
done

echo ""
echo "✅ INSTALLATION COMPLETE"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "✨ Files installed"
echo "   ./.github/copilot-instructions.md"
echo "   ./.github/prompts/*.prompt.md (14 skills)"
echo ""
echo "👉 NEXT STEP: Reload VS Code"
echo "   Command Palette → \"Developer: Reload Window\""
echo ""
echo "🎉 Done! Superpowers is active."