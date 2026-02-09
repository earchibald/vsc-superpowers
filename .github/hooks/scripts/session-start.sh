#!/usr/bin/env bash
# Copilot CLI Hook: Session Start
# Bootstrap Superpowers cache and display activation banner

set -euo pipefail

CACHE_DIR="${HOME}/.cache/superpowers"
SUPERPOWERS_REPO="https://github.com/obra/superpowers.git"

# Function to print banner
print_banner() {
    echo ""
    echo "🦸 ============================================"
    echo "🦸  Superpowers Active"
    echo "🦸 ============================================"
    echo ""
}

# Function to bootstrap cache (clone superpowers)
bootstrap_cache() {
    echo "Bootstrapping Superpowers cache..." >&2
    
    if git clone "$SUPERPOWERS_REPO" "$CACHE_DIR" 2>/dev/null; then
        echo "✓ Superpowers cache initialized" >&2
        return 0
    else
        echo "⚠ Failed to bootstrap Superpowers cache (network issue?)" >&2
        echo "  You can manually clone: git clone $SUPERPOWERS_REPO $CACHE_DIR" >&2
        return 1
    fi
}

# Function to update cache (git pull)
update_cache() {
    if [ -d "$CACHE_DIR/.git" ]; then
        echo "Updating Superpowers cache..." >&2
        
        if (cd "$CACHE_DIR" && git pull --quiet 2>/dev/null); then
            echo "✓ Superpowers cache updated" >&2
            return 0
        else
            # Fail silently on network errors - don't block session
            return 0
        fi
    fi
    return 0
}

# Main logic
main() {
    if [ ! -d "$CACHE_DIR" ]; then
        # Cache doesn't exist - bootstrap
        if ! bootstrap_cache; then
            # Bootstrap failed, but don't block session
            print_banner
            exit 0
        fi
    else
        # Cache exists - update it
        update_cache
    fi
    
    # Print success banner
    print_banner
    
    # Always exit 0 (never block copilot session)
    exit 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
