#!/usr/bin/env bash
# Shared library for verification marker management
# Source this file in test runners to enable verification marker creation

# Get project hash for a directory (defaults to current working directory)
get_project_hash() {
    local project_dir="${1:-$(pwd)}"
    # Try GNU md5sum first, fall back to macOS md5
    echo -n "$project_dir" | md5sum 2>/dev/null | cut -d' ' -f1 || \
    echo -n "$project_dir" | md5 2>/dev/null
}

# Create verification marker for successful test run
create_verification_marker() {
    local project_dir="${1:-$(pwd)}"
    local project_hash
    
    project_hash=$(get_project_hash "$project_dir")
    if [ -z "$project_hash" ]; then
        echo "Warning: Could not generate project hash" >&2
        return 1
    fi
    
    local marker_file="/tmp/.superpowers-verified-${project_hash}"
    local timestamp
    timestamp=$(date +%s)
    
    echo "$timestamp" > "$marker_file" 2>/dev/null || {
        echo "Warning: Could not create verification marker" >&2
        return 1
    }
    
    echo "✅ Verification marker created: $marker_file" >&2
    return 0
}

# Remove verification marker (for test cleanup or on failure)
remove_verification_marker() {
    local project_dir="${1:-$(pwd)}"
    local project_hash
    
    project_hash=$(get_project_hash "$project_dir")
    if [ -z "$project_hash" ]; then
        return 1
    fi
    
    local marker_file="/tmp/.superpowers-verified-${project_hash}"
    rm -f "$marker_file" 2>/dev/null
    return 0
}

# Check if verification marker exists and is recent
check_verification_status() {
    local project_dir="${1:-$(pwd)}"
    local max_age="${2:-3600}"  # Default 1 hour
    local project_hash
    
    project_hash=$(get_project_hash "$project_dir")
    if [ -z "$project_hash" ]; then
        echo "unknown"
        return 1
    fi
    
    local marker_file="/tmp/.superpowers-verified-${project_hash}"
    
    if [ ! -f "$marker_file" ]; then
        echo "missing"
        return 1
    fi
    
    local marker_time
    marker_time=$(cat "$marker_file" 2>/dev/null)
    if [ -z "$marker_time" ]; then
        echo "invalid"
        return 1
    fi
    
    local current_time
    current_time=$(date +%s)
    local age=$((current_time - marker_time))
    
    if [ $age -lt $max_age ]; then
        echo "recent"
        return 0
    else
        echo "stale"
        return 1
    fi
}
