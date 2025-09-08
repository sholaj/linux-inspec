# Linux InSpec

## Git Hooks Setup

This repository uses Git hooks to enforce commit message standards at both commit-time and push-time. The hooks validate commit messages automatically to maintain consistent commit history.

## Quick Setup

### Automatic Setup (Recommended)

Run the setup script after cloning the repository:

```bash
./scripts/setup-hooks.sh
```

This will automatically configure Git to use the repository's hooks.

### Manual Setup

Alternatively, configure manually:

```bash
# Set the Git hooks directory
git config core.hooksPath scripts/git-hooks
```

### Commit Message Format

The repository enforces the following commit message format:

#### Option 1: Simple Format (Any Project Prefix) - DEFAULT
```
<type>: <PROJECT>-<NUMBER> <description>
```
- **Types**: `feat`, `fix`, `update`, `test`
- **Examples**: 
  - `feat: JIRA-123 Add user authentication module`
  - `fix: TPE-456 Fix authentication bug`
  - `update: PROJ-789 Update dependencies`

#### Option 2: Conventional Commits Format
```
<type>(<scope>): <description>
```
- **Types**: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`
- **Example**: `feat(auth): add OAuth2 integration`

### Examples of Valid Commit Messages

- `feat: JIRA-123 Add new authentication module`
- `fix: TPE-456 Resolve memory leak in data processor`
- `update: PROJ-789 Improve error handling`
- `test: TICKET-999 Add integration tests for API`
- `feat(auth): implement OAuth2 integration`
- `fix(api): resolve race condition in request handler`
- `docs(readme): update installation instructions`
- `Merge branch 'feature/new-feature' into main`
- `Initial commit`

### Customizing the Validation Pattern

The commit message validation pattern can be easily modified by editing the regex in:
- `scripts/git-hooks/commit-msg` - For commit-time validation
- `scripts/git-hooks/pre-push` - For push-time validation

Look for the `COMMIT_REGEX` variable at the top of each file (line 8 or 11).

### Developer Guide

For detailed information on when to use each commit type, see [COMMIT_MESSAGE_GUIDE.md](COMMIT_MESSAGE_GUIDE.md).

### Bypassing the Hook (Not Recommended)

If you need to bypass the validation temporarily:
```bash
git push --no-verify
```

⚠️ **Warning**: Bypassing the hook should only be done in exceptional cases and may result in non-compliant commit history.

### Troubleshooting

If you encounter issues with the pre-push hook:

1. **Ensure the hook is executable**:
   ```bash
   chmod +x scripts/git-hooks/pre-push
   ```

2. **Verify the hooks path is set correctly**:
   ```bash
   git config core.hooksPath
   ```
   Should output: `scripts/git-hooks`

3. **Fix existing commit messages**:
   - To amend the last commit: `git commit --amend`
   - To fix multiple commits: `git rebase -i HEAD~n` (where n is the number of commits)

### Testing the Hook

To test that the hook is working correctly:

1. Create a commit with an invalid message:
   ```bash
   git commit -m "bad commit message"
   ```

2. Try to push:
   ```bash
   git push
   ```
   The push should be rejected with a helpful error message.

3. Fix the commit message:
   ```bash
   git commit --amend -m "feat: JIRA-001 Test commit message validation"
   ```

4. Push again:
   ```bash
   git push
   ```
   The push should succeed.

## Server-Side Setup (GitHub Actions)

Server-side validation ensures ALL developers follow commit standards, regardless of their local setup.

### GitHub Actions Setup

The repository already includes a GitHub Actions workflow at `.github/workflows/validate-commits.yml` that automatically validates commit messages.

#### How it Works

The workflow triggers on:
- **Pull Requests** - Validates all commits in the PR
- **Pushes to protected branches** - main, master, develop

#### Commit Message Validation

The workflow enforces the flexible project prefix pattern:
```
(feat|fix|update|test): [A-Z]+-[0-9]+ <description>
```
This supports any uppercase project prefix like JIRA-123, TPE-456, PROJ-789, etc.

#### What Happens on Validation Failure

When invalid commit messages are detected:
1. The GitHub Actions check will fail ❌
2. The PR cannot be merged until fixed
3. Clear error messages show which commits are invalid
4. Instructions are provided for fixing the commits

#### Customizing the Server-Side Pattern

To modify the validation pattern in GitHub Actions:
1. Edit `.github/workflows/validate-commits.yml`
2. Update the `COMMIT_REGEX` variable (line 25)
3. Commit and push the changes

#### Testing Server-Side Validation

1. Create a feature branch:
   ```bash
   git checkout -b test-validation
   ```

2. Create a commit with invalid message:
   ```bash
   git commit -m "bad message"
   ```

3. Push and create a PR:
   ```bash
   git push origin test-validation
   ```

4. The GitHub Actions check will fail, blocking the merge

5. Fix the commit:
   ```bash
   git commit --amend -m "fix: JIRA-123 Correct commit message"
   git push --force
   ```

6. The check will pass ✅

## Server vs Client Validation

| Aspect | Client-Side (pre-push) | Server-Side (GitHub Actions) |
|--------|------------------------|-------------------------------|
| **Enforcement** | Optional (can bypass with --no-verify) | Mandatory (blocks PR merge) |
| **Setup** | Each developer must configure | One-time repository setup |
| **Feedback** | Immediate, before push | On PR creation/push |
| **Performance** | No server load | Uses GitHub Actions minutes |
| **Best for** | Development teams with discipline | Strict enforcement needs |

## Recommended Approach

**Use both**:
1. **Client-side hooks** - Immediate developer feedback before pushing
2. **GitHub Actions** - Final enforcement at PR level

This provides the best developer experience while ensuring compliance.