# Commit Message Guide

This guide explains when and how to use each commit message type in this repository.

## Quick Reference

### Format Options

#### Option 1: Any Project Prefix (Default)
```
<type>: <PROJECT>-<NUMBER> <description>
```
Examples: 
- `feat: JIRA-123 Add user authentication`
- `fix: TPE-456 Fix authentication bug`
- `update: PROJ-789 Update dependencies`

#### Option 2: Conventional Commits
```
<type>(<scope>): <description>
```
Example: `feat(auth): add OAuth2 integration`

## Commit Types

### Core Types (Project Prefix Format)

#### `feat` - New Feature
Use when adding new functionality to the application.

**When to use:**
- Adding a new endpoint, API, or service
- Implementing a new user-facing feature
- Adding new capabilities to existing modules

**Examples:**
```
feat: JIRA-123 Add user registration endpoint
feat: JIRA-456 Implement dark mode toggle
feat: JIRA-789 Add export to CSV functionality
```

#### `fix` - Bug Fix
Use when fixing broken functionality.

**When to use:**
- Correcting logic errors
- Fixing crashes or exceptions
- Resolving incorrect behavior

**Examples:**
```
fix: JIRA-234 Resolve null pointer in user service
fix: JIRA-567 Fix incorrect date formatting
fix: JIRA-890 Correct validation logic for email
```

#### `update` - Updates to Existing Features
Use when modifying or enhancing existing functionality.

**When to use:**
- Improving existing features
- Updating dependencies
- Modifying existing behavior (not a bug fix)

**Examples:**
```
update: JIRA-345 Enhance search algorithm performance
update: JIRA-678 Improve error messages in validation
update: JIRA-901 Upgrade authentication flow
```

### Extended Types (Conventional Commits)

#### `build` - Build System
Changes to build configuration, dependencies, or tooling.

**Examples:**
```
build: update webpack configuration
build: add new dev dependency for testing
build: configure Docker multi-stage build
```

#### `chore` - Maintenance Tasks
Routine tasks that don't modify src or test files.

**Examples:**
```
chore: update .gitignore
chore: clean up deprecated files
chore: update license year
```

#### `ci` - Continuous Integration
Changes to CI/CD pipelines and configurations.

**Examples:**
```
ci: add GitHub Actions workflow
ci: update Jenkins pipeline configuration
ci: add automated security scanning
```

#### `docs` - Documentation
Documentation-only changes.

**Examples:**
```
docs: update API documentation
docs: add installation guide
docs: correct typos in README
```

#### `perf` - Performance Improvements
Changes that improve performance without changing functionality.

**Examples:**
```
perf: optimize database queries
perf: implement caching for API responses
perf: reduce bundle size by lazy loading
```

#### `refactor` - Code Refactoring
Code changes that neither fix bugs nor add features.

**Examples:**
```
refactor: extract common logic to utility function
refactor: rename variables for clarity
refactor: restructure module organization
```

#### `revert` - Revert Changes
Reverting previous commits.

**Examples:**
```
revert: revert commit abc123
revert: undo changes to authentication flow
```

#### `style` - Code Style
Changes that don't affect code meaning (formatting, semicolons, etc).

**Examples:**
```
style: apply consistent formatting
style: fix linting errors
style: organize imports
```

#### `test` - Testing
Adding or updating tests.

**Examples:**
```
test: add unit tests for user service
test: update integration tests for new API
test: add end-to-end test coverage
```

## Configuration

### Switching Between Formats

To switch between commit message formats, edit the appropriate hook file:

1. **For commit-time validation:** `scripts/git-hooks/commit-msg`
2. **For push-time validation:** `scripts/git-hooks/pre-push`

Comment/uncomment the desired `COMMIT_REGEX` pattern on lines 8 or 11.

### Installing Hooks

The hooks are automatically active when `core.hooksPath` is configured:

```bash
# Verify hooks are configured
git config core.hooksPath

# If not configured, set it up
git config core.hooksPath scripts/git-hooks
```

### Bypassing Hooks (Emergency Only)

In exceptional cases where you need to bypass validation:

```bash
# Bypass commit-time validation
git commit --no-verify -m "your message"

# Bypass push-time validation
git push --no-verify
```

**Note:** Use bypass only in emergencies. It's better to fix the commit message.

## Best Practices

1. **Be Specific:** Clearly describe what changed and why
2. **Keep It Concise:** First line should be under 72 characters
3. **Use Present Tense:** "Add feature" not "Added feature"
4. **Reference Issues:** Always include JIRA ticket when using JIRA format
5. **Separate Concerns:** One commit per logical change

## Troubleshooting

### Hook Not Running

Check if hooks path is configured:
```bash
git config core.hooksPath
```

### Permission Denied

Ensure hooks are executable:
```bash
chmod +x scripts/git-hooks/*
```

### Modifying Validation Rules

Edit the `COMMIT_REGEX` variable in:
- `scripts/git-hooks/commit-msg` (line 8 or 11)
- `scripts/git-hooks/pre-push` (line 8 or 11)

## Multi-line Commit Messages

For detailed descriptions, use multi-line format:

```bash
git commit -m "feat: JIRA-123 Add user authentication

- Implement OAuth2 flow
- Add JWT token validation
- Create user session management"
```

Only the first line is validated against the pattern.