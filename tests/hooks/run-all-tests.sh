#!/usr/bin/env bash
# Master test runner for all hooks tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source verification marker library
source "$SCRIPT_DIR/verification-lib.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Track overall results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

echo "========================================"
echo "Running All Hook Tests"
echo "========================================"
echo ""

# Run session-start tests
echo -e "${BLUE}Suite 1: Session Start Hook${NC}"
TOTAL_SUITES=$((TOTAL_SUITES + 1))
if "$SCRIPT_DIR/session-start.test.sh"; then
    PASSED_SUITES=$((PASSED_SUITES + 1))
else
    FAILED_SUITES=$((FAILED_SUITES + 1))
fi

echo ""
echo "========================================"
echo ""

# Run pre-command tests
echo -e "${BLUE}Suite 2: Pre-Command Hook${NC}"
TOTAL_SUITES=$((TOTAL_SUITES + 1))
if "$SCRIPT_DIR/pre-command.test.sh"; then
    PASSED_SUITES=$((PASSED_SUITES + 1))
else
    FAILED_SUITES=$((FAILED_SUITES + 1))
fi

echo ""
echo "========================================"
echo ""

# Run verification marker tests
echo -e "${BLUE}Suite 3: Verification Markers${NC}"
TOTAL_SUITES=$((TOTAL_SUITES + 1))
if "$SCRIPT_DIR/verification-marker.test.sh"; then
    PASSED_SUITES=$((PASSED_SUITES + 1))
else
    FAILED_SUITES=$((FAILED_SUITES + 1))
fi

echo ""
echo "========================================"
echo ""

# Run integration tests
echo -e "${BLUE}Suite 4: Verification Marker Integration${NC}"
TOTAL_SUITES=$((TOTAL_SUITES + 1))
if "$SCRIPT_DIR/integration.test.sh"; then
    PASSED_SUITES=$((PASSED_SUITES + 1))
else
    FAILED_SUITES=$((FAILED_SUITES + 1))
fi

echo ""
echo "========================================"
echo "Overall Results"
echo "========================================"
echo "Test suites run:    $TOTAL_SUITES"
echo -e "Test suites passed: ${GREEN}$PASSED_SUITES${NC}"
echo -e "Test suites failed: ${RED}$FAILED_SUITES${NC}"
echo ""

if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "${GREEN}✓ All test suites passed!${NC}"
    echo ""
    
    # Create verification marker on success
    create_verification_marker "$PROJECT_ROOT"
    
    exit 0
else
    echo -e "${RED}✗ Some test suites failed${NC}"
    echo ""
    
    # Remove verification marker on failure
    remove_verification_marker "$PROJECT_ROOT"
    
    exit 1
fi
