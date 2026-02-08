#!/bin/bash

# Development Environment Setup Script
# This script helps new developers get the Superpowers framework fully configured
# for development after cloning the repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

echo "🚀 Superpowers Development Environment Setup"
echo "=============================================="
echo ""

# Check if we're in a Git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not in a Git repository. Please clone the repository first."
    exit 1
fi

echo "📁 Setting up in: $PROJECT_ROOT"
echo ""

# Step 1: Verify installation script
echo "Step 1️⃣  Preparing installer..."
if [ ! -f "$PROJECT_ROOT/install-superpowers.sh" ]; then
    echo "❌ install-superpowers.sh not found!"
    exit 1
fi

# Make installer executable
chmod +x "$PROJECT_ROOT/install-superpowers.sh"
echo "✓ Installer ready"
echo ""

# Step 2: Create local development directories (if needed)
echo "Step 2️⃣  Creating development directories..."
mkdir -p "$PROJECT_ROOT/.vscode" 2>/dev/null || true
mkdir -p "$PROJECT_ROOT/.cache" 2>/dev/null || true
echo "✓ Directories ready"
echo ""

# Step 3: Recommend .vscode/settings.json
echo "Step 3️⃣  VS Code settings (optional)..."
echo "    Consider creating .vscode/settings.json with your preferences"
echo "    Example entries:"
echo "      - editor.formatOnSave: true"
echo "      - editor.defaultFormatter: (your language)"
echo "      - markdown.preview.breaks: true"
echo ""

# Step 4: Install Superpowers framework
echo "Step 4️⃣  Installing Superpowers framework..."
echo ""
"$PROJECT_ROOT/install-superpowers.sh"
echo ""

# Step 5: Verification
echo "Step 5️⃣  Verifying installation..."
if [ -f "$PROJECT_ROOT/scripts/verify-installation.sh" ]; then
    chmod +x "$PROJECT_ROOT/scripts/verify-installation.sh"
    "$PROJECT_ROOT/scripts/verify-installation.sh"
    echo ""
else
    echo "⚠️  Verification script not found. Manual verification recommended."
    echo ""
fi

# Step 6: Next steps
echo "✅ Development environment setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Reload VS Code (Command Palette → Developer: Reload Window)"
echo "   2. Verify slash commands are available (Copilot Chat → type '/')"
echo "   3. Check plan.md for the current work"
echo ""
echo "🎯 Ready to work! Use slash commands:"
echo "   • /brainstorm - Explore & design ideas"
echo "   • /write-plan - Create implementation plans"
echo "   • /tdd - Test-driven development"
echo "   • /investigate - Debug issues"
echo "   • /verify - Validate changes"
echo "   • /worktree - Create isolated workspaces"
echo "   • And 8 more... (type /superpowers to learn all)"
echo ""
