#!/usr/bin/env bash
# Copilot CLI Hook: Pre-Command (preToolUse)
# Enforce Iron Law of Verification before dangerous commands

set -euo pipefail

# Parse JSON input from stdin
INPUT=""
if [ -t 0 ]; then
    # No stdin (testing)
    INPUT=""
else
    # Read from stdin
    INPUT=$(cat)
fi

# Parse JSON using jq if available, otherwise use grep/sed
parse_json() {
    local json="$1"
    local field="$2"
    
    if command -v jq >/dev/null 2>&1; then
        echo "$json" | jq -r "$field" 2>/dev/null || echo ""
    else
        # Fallback to grep/sed for simple parsing
        echo "$json" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*:"\([^"]*\)".*/\1/' | head -1
    fi
}

# Extract command from JSON payload
extract_command() {
    local json="$1"
    
    if command -v jq >/dev/null 2>&1; then
        # Use jq to parse nested JSON
        echo "$json" | jq -r '.toolArgs | fromjson | .command' 2>/dev/null || echo ""
    else
        # Fallback: extract toolArgs value and then extract command from it
        local tool_args
        tool_args=$(echo "$json" | grep -o '"toolArgs"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:"\(.*\)"/\1/')
        
        if [ -z "$tool_args" ]; then
            return 0
        fi
        
        # Unescape the JSON string (replace \" with ")
        tool_args=$(echo "$tool_args" | sed 's/\\"/"/g')
        
        # Extract command from unescaped JSON
        local command
        command=$(echo "$tool_args" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:"\(.*\)"/\1/')
        
        echo "$command"
    fi
}

# Check if command is a dangerous operation (commit/push)
is_dangerous_command() {
    local cmd="$1"
    
    if echo "$cmd" | grep -qiE '(git[[:space:]]+commit|git[[:space:]]+push)'; then
        return 0
    fi
    
    return 1
}

# Generate project hash for verification marker
get_project_hash() {
    local cwd="$1"
    
    # Use PROJECT_HASH env var if set (for testing)
    if [ -n "${PROJECT_HASH:-}" ]; then
        echo "$PROJECT_HASH"
        return 0
    fi
    
    # Otherwise compute from cwd
    if [ -n "$cwd" ]; then
        echo "$cwd" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "default"
    else
        echo "default"
    fi
}

# Check verification marker
check_verification() {
    local cwd="$1"
    local project_hash
    project_hash=$(get_project_hash "$cwd")
    local marker_file="/tmp/.superpowers-verified-${project_hash}"
    
    if [ ! -f "$marker_file" ]; then
        echo "⚠️  Iron Law Warning: No recent test verification found" >&2
        echo "   Run tests before committing to ensure quality" >&2
        return 1
    fi
    
    # Check if marker is stale (older than 1 hour = 3600 seconds)
    if command -v stat >/dev/null 2>&1; then
        local marker_time
        marker_time=$(stat -f %m "$marker_file" 2>/dev/null || stat -c %Y "$marker_file" 2>/dev/null || echo 0)
        local current_time
        current_time=$(date +%s)
        local age=$((current_time - marker_time))
        
        if [ "$age" -gt 3600 ]; then
            echo "⚠️  Iron Law Warning: Test verification is stale (>1 hour old)" >&2
           echo "   Run tests again to ensure recent changes are verified" >&2
            return 1
        fi
    fi
    
    return 0
}

# Main logic
main() {
    # Empty input - nothing to check
    if [ -z "$INPUT" ]; then
        exit 0
    fi
    
    # Extract command from JSON
    local command
    command=$(extract_command "$INPUT")
    
    # Extract cwd from JSON
    local cwd
    cwd=$(parse_json "$INPUT" "cwd")
    if [ -z "$cwd" ]; then
        cwd="$PWD"
    fi
    
    # Empty command - nothing to check
    if [ -z "$command" ]; then
        exit 0
    fi
    
    # Check if this is a dangerous command
    if is_dangerous_command "$command"; then
        # Check verification marker
        if ! check_verification "$cwd"; then
            # Warning already printed to stderr
            # But we still exit 0 (warn, don't block)
            exit 0
        fi
    fi
    
    # All good - allow command
    exit 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
