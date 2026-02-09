#!/bin/bash
# Bootstrap Superpowers cache from upstream repository
# This script initializes ~/.cache/superpowers if it doesn't exist
# Called by plugin on first use or during setup
#
# Environment Variables:
#   SUPERPOWERS_CACHE_DIR  - Override default cache location (for testing)
#   SUPERPOWERS_REPO_URL   - Override upstream repository (for testing)

set -e

# Allow override for testing
CACHE_DIR="${SUPERPOWERS_CACHE_DIR:-${HOME}/.cache/superpowers}"
REPO_URL="${SUPERPOWERS_REPO_URL:-https://github.com/obra/superpowers.git}"

echo "📦 Bootstrapping Superpowers cache..."

# Check if cache already exists
if [ -d "$CACHE_DIR" ]; then
    echo "✅ Cache already exists at $CACHE_DIR"
    echo "   (Run 'cd $CACHE_DIR && git pull' to update)"
    exit 0
fi

# Create cache directory
echo "📁 Creating cache directory: $CACHE_DIR"
mkdir -p "$(dirname "$CACHE_DIR")"

# Clone upstream repository
echo "🔄 Cloning upstream repository..."
git clone "$REPO_URL" "$CACHE_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Bootstrap complete!"
    echo ""
    echo "Cache location: $CACHE_DIR"
    echo "Skills available: $(find "$CACHE_DIR/skills" -maxdepth 1 -type d | wc -l) directories"
    echo ""
    echo "To update in future:"
    echo "  cd $CACHE_DIR && git pull"
    exit 0
else
    echo "❌ Failed to clone repository"
    echo "   Check your internet connection and try again"
    exit 1
fi
