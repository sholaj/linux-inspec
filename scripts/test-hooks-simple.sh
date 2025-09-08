#!/bin/bash

# Simple test script for Git hooks validation

echo "=== Git Hooks Test ==="

# Test valid messages
echo "Testing valid messages:"
echo -n "  feat: JIRA-123 Add feature... "
echo "feat: JIRA-123 Add feature" > /tmp/test_msg && scripts/git-hooks/commit-msg /tmp/test_msg >/dev/null 2>&1 && echo "✓" || echo "✗"

echo -n "  fix: TPE-456 Fix bug... "
echo "fix: TPE-456 Fix bug" > /tmp/test_msg && scripts/git-hooks/commit-msg /tmp/test_msg >/dev/null 2>&1 && echo "✓" || echo "✗"

echo -n "  update: PROJ-789 Update code... "
echo "update: PROJ-789 Update code" > /tmp/test_msg && scripts/git-hooks/commit-msg /tmp/test_msg >/dev/null 2>&1 && echo "✓" || echo "✗"

echo -n "  test: ABC-1 Add tests... "
echo "test: ABC-1 Add tests" > /tmp/test_msg && scripts/git-hooks/commit-msg /tmp/test_msg >/dev/null 2>&1 && echo "✓" || echo "✗"

echo ""
echo "Testing invalid messages:"
echo -n "  invalid message... "
echo "invalid message" > /tmp/test_msg && scripts/git-hooks/commit-msg /tmp/test_msg >/dev/null 2>&1 && echo "✗ (should fail)" || echo "✓"

echo -n "  feat: missing-number Description... "
echo "feat: missing-number Description" > /tmp/test_msg && scripts/git-hooks/commit-msg /tmp/test_msg >/dev/null 2>&1 && echo "✗ (should fail)" || echo "✓"

echo -n "  badtype: JIRA-123 Description... "
echo "badtype: JIRA-123 Description" > /tmp/test_msg && scripts/git-hooks/commit-msg /tmp/test_msg >/dev/null 2>&1 && echo "✗ (should fail)" || echo "✓"

rm -f /tmp/test_msg

echo ""
echo "Hook validation test completed!"