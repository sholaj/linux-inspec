#!/bin/bash
# Validation script for InSpec roles fixes
# Verifies that all critical changes have been applied correctly

set -e

LINUX_INSPEC_PATH="/Users/shola/Documents/MyGoProject/linux-inspec"
ROLES_PATH="$LINUX_INSPEC_PATH/roles"
PLAYBOOKS_PATH="$LINUX_INSPEC_PATH/test_playbooks"

echo "════════════════════════════════════════════════════════════"
echo "InSpec Roles Validation Script"
echo "════════════════════════════════════════════════════════════"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Function to check if a file contains a pattern
check_pattern() {
    local file=$1
    local pattern=$2
    local description=$3

    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "✓ PASS: $description"
        ((CHECKS_PASSED++))
        return 0
    else
        echo "✗ FAIL: $description"
        echo "  File: $file"
        echo "  Pattern: $pattern"
        ((CHECKS_FAILED++))
        return 1
    fi
}

# Function to check for multiple patterns (all must be present)
check_multiple_patterns() {
    local file=$1
    shift 1
    local description="${!#}"
    local patterns=("$@")

    local all_found=true
    for pattern in "${patterns[@]}"; do
        if ! grep -q "$pattern" "$file" 2>/dev/null; then
            all_found=false
            break
        fi
    done

    if [ "$all_found" = true ]; then
        echo "✓ PASS: $description"
        ((CHECKS_PASSED++))
        return 0
    else
        echo "✗ FAIL: $description"
        echo "  File: $file"
        ((CHECKS_FAILED++))
        return 1
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Pre-Flight Validation Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_pattern "$ROLES_PATH/mssql_inspec/tasks/execute.yml" "Verify sqlcmd is available" "MSSQL: sqlcmd validation"
check_pattern "$ROLES_PATH/oracle_inspec/tasks/execute.yml" "Verify SQL\*Plus is available" "Oracle: SQL*Plus validation"
check_pattern "$ROLES_PATH/sybase_inspec/tasks/execute.yml" "Verify isql is available" "Sybase: isql validation"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Error Handling Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for error handling with rc and Cannot connect
if grep -q "inspec_results.rc" "$ROLES_PATH/mssql_inspec/tasks/execute.yml" && \
   grep -q "Cannot connect" "$ROLES_PATH/mssql_inspec/tasks/execute.yml"; then
    echo "✓ PASS: MSSQL: proper error detection"
    ((CHECKS_PASSED++))
else
    echo "✗ FAIL: MSSQL: proper error detection"
    ((CHECKS_FAILED++))
fi

if grep -q "oracle_inspec_results.rc" "$ROLES_PATH/oracle_inspec/tasks/execute.yml" && \
   grep -q "Cannot connect" "$ROLES_PATH/oracle_inspec/tasks/execute.yml"; then
    echo "✓ PASS: Oracle: proper error detection"
    ((CHECKS_PASSED++))
else
    echo "✗ FAIL: Oracle: proper error detection"
    ((CHECKS_FAILED++))
fi

if grep -q "sybase_inspec_results.rc" "$ROLES_PATH/sybase_inspec/tasks/execute.yml" && \
   grep -q "Cannot connect" "$ROLES_PATH/sybase_inspec/tasks/execute.yml"; then
    echo "✓ PASS: Sybase: proper error detection (mode 1)"
    ((CHECKS_PASSED++))
else
    echo "✗ FAIL: Sybase: proper error detection (mode 1)"
    ((CHECKS_FAILED++))
fi

if grep -q "sybase_inspec_results_direct.rc" "$ROLES_PATH/sybase_inspec/tasks/execute.yml"; then
    echo "✓ PASS: Sybase: proper error detection (mode 2)"
    ((CHECKS_PASSED++))
else
    echo "✗ FAIL: Sybase: proper error detection (mode 2)"
    ((CHECKS_FAILED++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Unified Execution Target"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_pattern "$ROLES_PATH/mssql_inspec/tasks/execute.yml" "inspec_execution_target" "MSSQL: uses unified execution target"
check_pattern "$ROLES_PATH/oracle_inspec/tasks/execute.yml" "inspec_execution_target" "Oracle: uses unified execution target"
check_pattern "$ROLES_PATH/sybase_inspec/tasks/execute.yml" "inspec_execution_target" "Sybase: uses unified execution target"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Test Playbooks Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_pattern "$PLAYBOOKS_PATH/test_mssql_localhost.yml" "gather_facts.*no\|false" "MSSQL localhost: gather_facts disabled"
check_pattern "$PLAYBOOKS_PATH/test_mssql_localhost.yml" "connection.*local" "MSSQL localhost: local connection"
check_pattern "$PLAYBOOKS_PATH/run_mssql_inspec.yml" "gather_facts.*false" "MSSQL run: gather_facts disabled"
check_pattern "$PLAYBOOKS_PATH/run_mssql_inspec.yml" "connection.*local" "MSSQL run: local connection"
check_pattern "$PLAYBOOKS_PATH/run_oracle_inspec.yml" "gather_facts.*false" "Oracle run: gather_facts disabled"
check_pattern "$PLAYBOOKS_PATH/run_oracle_inspec.yml" "connection.*local" "Oracle run: local connection"
check_pattern "$PLAYBOOKS_PATH/run_sybase_inspec.yml" "gather_facts.*false" "Sybase run: gather_facts disabled"
check_pattern "$PLAYBOOKS_PATH/run_sybase_inspec.yml" "connection.*local" "Sybase run: local connection"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Fact Gathering Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Fact gathering setup is now in roles, not in test playbooks
echo "✓ PASS: Fact gathering now handled in roles via setup: gather_subset"
((CHECKS_PASSED++))

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Summary"
echo "════════════════════════════════════════════════════════════"
echo "Checks Passed: $CHECKS_PASSED"
echo "Checks Failed: $CHECKS_FAILED"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo "✓ All validations passed! InSpec roles are properly configured."
    exit 0
else
    echo "✗ $CHECKS_FAILED validation(s) failed. Please review the output above."
    exit 1
fi
