#!/bin/bash

# Test script for Git hooks validation
# This script tests both commit-msg and pre-push hooks with various commit message formats

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test results
print_test_result() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo -e "  Expected: $expected"
        echo -e "  Actual: $actual"
        ((TESTS_FAILED++))
    fi
}

# Function to test commit message validation
test_commit_message() {
    local message="$1"
    local expected_result="$2"
    local test_name="$3"
    
    # Test using the commit-msg hook directly
    echo "$message" > /tmp/test_commit_msg
    
    if scripts/git-hooks/commit-msg /tmp/test_commit_msg >/dev/null 2>&1; then
        actual_result="valid"
    else
        actual_result="invalid"
    fi
    
    rm -f /tmp/test_commit_msg
    print_test_result "$test_name" "$expected_result" "$actual_result"
}

echo -e "${BLUE}=== Git Hooks Validation Test Suite ===${NC}"
echo ""

# Check if hooks exist
echo -e "${YELLOW}Checking hook files...${NC}"
if [ ! -f "scripts/git-hooks/commit-msg" ]; then
    echo -e "${RED}ERROR: commit-msg hook not found${NC}"
    exit 1
fi

if [ ! -f "scripts/git-hooks/pre-push" ]; then
    echo -e "${RED}ERROR: pre-push hook not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Hook files found${NC}"
echo ""

# Test valid commit messages
echo -e "${YELLOW}Testing valid commit messages...${NC}"

test_commit_message "feat: JIRA-123 Add user authentication" "valid" "JIRA prefix with feat"
test_commit_message "fix: TPE-456 Fix memory leak" "valid" "TPE prefix with fix" 
test_commit_message "update: PROJ-789 Update dependencies" "valid" "PROJ prefix with update"
test_commit_message "test: TICKET-999 Add unit tests" "valid" "TICKET prefix with test"
test_commit_message "feat: ABC-1 Minimal description" "valid" "Short project prefix"
test_commit_message "fix: LONGPROJECT-12345 Very long ticket number" "valid" "Long project prefix and number"

echo ""

# Test invalid commit messages
echo -e "${YELLOW}Testing invalid commit messages...${NC}"

test_commit_message "invalid commit message" "invalid" "No format structure"
test_commit_message "feat: missing ticket number" "invalid" "Missing ticket number"
test_commit_message "badtype: JIRA-123 Invalid type" "invalid" "Invalid commit type"
test_commit_message "feat:JIRA-123 No space after colon" "invalid" "No space after colon"
test_commit_message "feat: jira-123 Lowercase prefix" "invalid" "Lowercase project prefix"
test_commit_message "feat: JIRA- Missing number" "invalid" "Missing ticket number"
test_commit_message "feat: JIRA-abc Non-numeric ticket" "invalid" "Non-numeric ticket number"
test_commit_message "feat: JIRA-123" "invalid" "Missing description"

echo ""

# Test edge cases
echo -e "${YELLOW}Testing edge cases...${NC}"

test_commit_message "feat: A-1 Single letter prefix" "valid" "Single letter project prefix"
test_commit_message "feat: ABCDEFGHIJ-999999 Long prefix and number" "valid" "Very long prefix and number"
test_commit_message "feat: JIRA-123 Description with special chars !@#$%^&*()" "valid" "Special characters in description"

echo ""

# Summary
echo -e "${BLUE}=== Test Results ===${NC}"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi