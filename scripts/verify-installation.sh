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
