# Git Commit Standards Implementation Guide

## 📋 Table of Contents
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Step-by-Step Implementation](#step-by-step-implementation)
- [Verification & Testing](#verification--testing)
- [Rollout Strategy](#rollout-strategy)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

## 🚀 Quick Start

**For developers who want to get started immediately:**

```bash
# Clone this repository with the hooks
git clone <your-repo-url>
cd <your-repo>

# Enable the pre-push hook
git config core.hooksPath scripts/git-hooks

# That's it! Your commits will now be validated before pushing
```

## 📝 Prerequisites

Before implementing the Git hooks, ensure you have:

- [ ] Git version 2.9+ (for `core.hooksPath` support)
- [ ] Admin access to your GitHub repository (for GitHub Actions)
- [ ] Basic understanding of Git hooks and CI/CD

Check your Git version:
```bash
git --version
# Should output: git version 2.9.0 or higher
```

## 📚 Step-by-Step Implementation

### Phase 1: Repository Setup (5 minutes)

#### Step 1.1: Copy Hook Scripts
```bash
# Create the hooks directory in your repository
mkdir -p scripts/git-hooks

# Copy the pre-push hook from this repository
cp /path/to/linux-inspec/scripts/git-hooks/pre-push scripts/git-hooks/
cp /path/to/linux-inspec/scripts/git-hooks/github-action.yml scripts/git-hooks/

# Make the hook executable
chmod +x scripts/git-hooks/pre-push
```

#### Step 1.2: Configure Commit Pattern (Optional)
Edit `scripts/git-hooks/pre-push` line 11 to customize your regex pattern:

```bash
# Default pattern (Conventional Commits + JIRA)
COMMIT_REGEX='^((build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\(\w+\))?(!)?(: (.*\s*)*))|(Merge (.*\s*)*)|(Initial commit$)'

# Simple JIRA-only pattern (alternative)
# COMMIT_REGEX='^(feat|fix): JIRA-[0-9]{3,} .+'
```

#### Step 1.3: Add Documentation
```bash
# Copy the README section or create your own
cp /path/to/linux-inspec/README.md README.md
# Edit to match your project's needs
```

### Phase 2: Client-Side Setup (2 minutes per developer)

#### Step 2.1: Enable for Individual Developers

**Option A: Manual Setup (Each Developer)**
```bash
# Each developer runs this after cloning
git config core.hooksPath scripts/git-hooks
```

**Option B: Automated Setup Script**
Create `scripts/setup-dev.sh`:
```bash
#!/bin/bash
echo "🔧 Setting up Git hooks..."
git config core.hooksPath scripts/git-hooks
echo "✅ Git hooks enabled!"
echo "📝 Commit format: <type>(<scope>): <description>"
echo "   Example: feat(auth): add login functionality"
```

#### Step 2.2: Verify Client-Side Setup
```bash
# Check if hooks are configured
git config core.hooksPath
# Should output: scripts/git-hooks

# Test with an invalid commit
git commit -m "bad commit" --allow-empty
git push  # Should be rejected
```

### Phase 3: Server-Side Setup (10 minutes)

#### Step 3.1: Create GitHub Actions Workflow
```bash
# Create the workflow directory
mkdir -p .github/workflows

# Copy the GitHub Actions workflow
cp scripts/git-hooks/github-action.yml .github/workflows/validate-commits.yml
```

#### Step 3.2: Commit and Push the Workflow
```bash
# Add all hook files and workflow
git add scripts/git-hooks/
git add .github/workflows/validate-commits.yml
git add README.md

# Commit with a valid message
git commit -m "feat: add commit message validation hooks"

# Push to enable GitHub Actions
git push origin main
```

#### Step 3.3: Configure Branch Protection (GitHub UI)

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Branches**
3. Add rule for `main` branch (or your default branch)
4. Enable:
   - ✅ **Require status checks to pass before merging**
   - ✅ **Require branches to be up to date before merging**
   - Select `validate-commits` as required status check
5. Click **Create** or **Save changes**

### Phase 4: Team Rollout (1-2 weeks)

#### Step 4.1: Communication Plan

**Week 1: Soft Launch**
```markdown
# Email/Slack Template
Subject: New Commit Message Standards - Soft Launch

Team,

Starting today, we're implementing commit message standards to improve our Git history.

**What's changing:**
- Commits must follow the format: type(scope): description
- Example: feat(api): add user authentication

**Action required:**
Run this command in your local repo:
git config core.hooksPath scripts/git-hooks

**Resources:**
- Full guide: [link to README]
- Valid types: feat, fix, docs, style, refactor, test, chore

This is currently optional but will be mandatory next week.
```

#### Step 4.2: Progressive Enforcement

**Day 1-3: Education Mode**
- Client-side hooks only (warnings)
- Help developers learn the format

**Day 4-7: Soft Enforcement**
- Client-side hooks active
- GitHub Actions runs but doesn't block

**Week 2: Full Enforcement**
- GitHub Actions blocks non-compliant PRs
- All commits must pass validation

## ✅ Verification & Testing

### Test Client-Side Hook

```bash
# Test 1: Invalid commit (should fail)
echo "test" > test.txt
git add test.txt
git commit -m "wrong format"
git push  # Should be rejected

# Test 2: Valid JIRA format (should pass)
git commit --amend -m "feat: JIRA-123 add test file"
git push  # Should succeed

# Test 3: Valid conventional format (should pass)
git commit --amend -m "feat(testing): add test file"
git push  # Should succeed

# Test 4: Bypass in emergency (use sparingly)
git push --no-verify  # Bypasses client-side check
```

### Test GitHub Actions

```bash
# Create a test branch
git checkout -b test/commit-validation

# Make changes with invalid commit
echo "test" > test.txt
git add test.txt
git commit -m "bad commit message"
git push origin test/commit-validation

# Create PR - should see failing check
# Fix the commit
git commit --amend -m "test: validate commit hooks"
git push --force

# PR check should now pass
```

## 🔄 Rollout Strategy

### Recommended Timeline

| Week | Phase | Actions | Enforcement Level |
|------|-------|---------|-------------------|
| 0 | Preparation | Setup scripts, documentation | None |
| 1 | Soft Launch | Team communication, training | Client-side only (optional) |
| 2 | Adoption | Support, collect feedback | Client-side (required) |
| 3 | Enforcement | Enable GitHub Actions | Server-side (blocking) |
| 4 | Optimization | Refine patterns, add tooling | Full enforcement |

### Success Metrics

Track these metrics to measure adoption:

```bash
# Check compliance rate (run weekly)
git log --since="1 week ago" --pretty=format:"%s" | while read msg; do
  if echo "$msg" | grep -qE '^(feat|fix|docs|test|chore|style|refactor)(\(.+\))?: .+'; then
    echo "✓ $msg"
  else
    echo "✗ $msg"
  fi
done | sort | uniq -c
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Hook not executing"
```bash
# Solution: Check hook permissions
ls -la scripts/git-hooks/pre-push
# Should show: -rwxr-xr-x

# Fix permissions
chmod +x scripts/git-hooks/pre-push
```

#### Issue 2: "Push rejected but commit is valid"
```bash
# Solution: Check which regex is active
grep "^COMMIT_REGEX=" scripts/git-hooks/pre-push

# Test your message against the regex
echo "your commit message" | grep -E 'your-regex-pattern'
```

#### Issue 3: "GitHub Action not running"
```yaml
# Solution: Check workflow file location
ls -la .github/workflows/validate-commits.yml

# Verify workflow syntax
# Go to Actions tab in GitHub to see any errors
```

#### Issue 4: "Need to fix multiple commits"
```bash
# Interactive rebase to fix last 3 commits
git rebase -i HEAD~3

# Change 'pick' to 'reword' for commits to fix
# Save and close, then update each message
```

#### Issue 5: "Emergency push needed"
```bash
# Client-side bypass (use sparingly)
git push --no-verify

# Document why bypass was needed
git notes add -m "Emergency fix: bypassed validation due to production issue"
```

## ❓ FAQ

### Q: Can I use different patterns for different branches?
**A:** Not with the current setup. You'd need to modify the hook to check branch names.

### Q: What about existing commits?
**A:** Existing commits are not affected. Only new commits after implementation are validated.

### Q: Can I customize the error message?
**A:** Yes, edit the error output section in `scripts/git-hooks/pre-push` (lines 60-80).

### Q: How do I disable temporarily?
**A:** Run `git config --unset core.hooksPath` to disable, re-enable with `git config core.hooksPath scripts/git-hooks`

### Q: What about squash merges?
**A:** GitHub squash merges create a new commit message that should follow the standards.

### Q: Can this work with other CI systems?
**A:** Yes, but you'll need to adapt the GitHub Actions workflow to your CI system.

## 📊 Monitoring & Reporting

### Generate Compliance Report
Create `scripts/commit-report.sh`:

```bash
#!/bin/bash
echo "=== Commit Compliance Report ==="
echo "Date: $(date)"
echo "Repository: $(basename $(git rev-parse --show-toplevel))"
echo ""

# Count compliant vs non-compliant
total=$(git log --since="30 days ago" --oneline | wc -l)
compliant=$(git log --since="30 days ago" --pretty=format:"%s" | grep -cE '^(feat|fix|docs|test|chore|style|refactor)(\(.+\))?: .+')

echo "Last 30 days:"
echo "- Total commits: $total"
echo "- Compliant: $compliant"
echo "- Non-compliant: $((total - compliant))"
echo "- Compliance rate: $((compliant * 100 / total))%"
```

## 🎯 Success Criteria

Your implementation is successful when:

- [ ] 95%+ commits follow the standard format
- [ ] All PRs pass commit validation checks
- [ ] Team reports improved Git history clarity
- [ ] No significant workflow disruptions
- [ ] Rollback procedure is documented and tested

## 📚 Additional Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 💡 Tips for Success

1. **Start with education, not enforcement**
2. **Provide clear examples relevant to your codebase**
3. **Set up a Slack channel for questions**
4. **Celebrate good commit messages publicly**
5. **Use automation to reduce friction**
6. **Keep the regex simple initially**
7. **Document exceptions and edge cases**
8. **Monitor metrics and adjust accordingly**

---

**Need help?** Create an issue in the repository or contact the platform team.