#!/bin/bash
# =============================================================================
# run_sqlcmd_diagnostics.sh
# Quick-start script for diagnosing and fixing sqlcmd PATH issues
# =============================================================================
#
# Usage:
#   ./run_sqlcmd_diagnostics.sh <delegate_host>
#
# Example:
#   ./run_sqlcmd_diagnostics.sh <DELEGATE_HOST>
#
# This script will:
#   1. Run the diagnostic playbook to identify PATH issues
#   2. Run the validation playbook to confirm the fix
#   3. Display a summary of results
#
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         SQLCMD PATH DIAGNOSTIC AND FIX UTILITY               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check for delegate host argument
DELEGATE_HOST="${1:-localhost}"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Delegate Host: ${DELEGATE_HOST}"
echo ""

# Check if playbooks exist
if [[ ! -f "diagnose_sqlcmd_path.yml" ]]; then
    echo -e "${RED}Error: diagnose_sqlcmd_path.yml not found${NC}"
    echo "Please ensure you're running this script from the directory containing the playbooks."
    exit 1
fi

# Step 1: Run Diagnostic Playbook
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 1: Running Diagnostic Playbook${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

ansible-playbook diagnose_sqlcmd_path.yml \
    -e "inspec_delegate_host=${DELEGATE_HOST}" \
    -v

DIAG_EXIT_CODE=$?

if [[ $DIAG_EXIT_CODE -ne 0 ]]; then
    echo -e "${RED}Diagnostic playbook failed with exit code: ${DIAG_EXIT_CODE}${NC}"
    exit $DIAG_EXIT_CODE
fi

echo ""
echo -e "${GREEN}✅ Diagnostic playbook completed${NC}"
echo ""

# Step 2: Run Validation Playbook
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 2: Running Validation Playbook${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

ansible-playbook validate_sqlcmd_fix.yml \
    -e "inspec_delegate_host=${DELEGATE_HOST}" \
    -v

VALID_EXIT_CODE=$?

if [[ $VALID_EXIT_CODE -ne 0 ]]; then
    echo -e "${YELLOW}Validation playbook completed with warnings (exit code: ${VALID_EXIT_CODE})${NC}"
else
    echo -e "${GREEN}✅ Validation playbook completed successfully${NC}"
fi

echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Diagnostic Exit Code: ${DIAG_EXIT_CODE}"
echo "Validation Exit Code: ${VALID_EXIT_CODE}"
echo ""

if [[ $DIAG_EXIT_CODE -eq 0 && $VALID_EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ ALL TESTS PASSED - Ready to apply fix!                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Next Steps:"
    echo "  1. Copy execute_fixed.yml to mssql_inspec/tasks/execute.yml"
    echo "  2. Update mssql_environment_vars.yml with your environment paths"
    echo "  3. Run a test scan in AAP2"
else
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  Some tests had issues - review output above             ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Troubleshooting Steps:"
    echo "  1. Verify sqlcmd is installed on ${DELEGATE_HOST}"
    echo "  2. Check the PATH configuration in mssql_environment_vars.yml"
    echo "  3. Ensure delegate host is accessible"
fi

echo ""
echo -e "${BLUE}For manual testing, run:${NC}"
echo "  ssh ${DELEGATE_HOST} 'export PATH=/opt/mssql-tools/bin:\$PATH && which sqlcmd'"
echo ""
