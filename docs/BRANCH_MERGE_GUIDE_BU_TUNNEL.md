# Branch Merge Guide: BU-Specific Tunnel Configuration

## Context

- `feature/mssql-scan` — base feature branch (generic MSSQL scanning)
- Colleague's branch — forked from `feature/mssql-scan`, adds BU-specific tunnel connectivity
- The BU-specific changes should remain configurable, not hardcoded

## Branch Structure

```
main
  └── feature/mssql-scan (yours - generic)
        └── colleague/mssql-scan-bu-tunnel (BU-specific tunnel changes)
```

## Recommended Approach: Cherry-Pick + Parameterise

Since the changes are BU-specific (tunnel connectivity for one affiliate), don't merge the entire branch directly. Instead, extract the reusable parts and make them configurable.

### Step 1: Review the Diff

```bash
# See exactly what your colleague changed
git fetch origin
git diff feature/mssql-scan...origin/<colleague-branch-name>

# See commit-by-commit
git log feature/mssql-scan..origin/<colleague-branch-name> --oneline
```

### Step 2: Categorise the Changes

Sort each change into one of these buckets:

| Category | Action | Example |
|----------|--------|---------|
| **Bug fix** | Merge directly | Connection timeout fix, error handling |
| **Generic enhancement** | Merge directly | New variable support, better logging |
| **BU-specific hardcoding** | Parameterise first | Hardcoded tunnel host, BU-specific ports |
| **Tunnel connectivity** | Make configurable | SSH tunnel setup, proxy configuration |

### Step 3: Cherry-Pick Bug Fixes and Generic Enhancements

```bash
git checkout feature/mssql-scan

# Cherry-pick individual commits that are generic/bug fixes
git cherry-pick <commit-hash-1>
git cherry-pick <commit-hash-2>
```

### Step 4: Parameterise Tunnel Connectivity

If the colleague hardcoded tunnel details, refactor them into variables:

```yaml
# group_vars or inventory - BU-specific
# Instead of hardcoded tunnel host:
mssql_use_tunnel: true
mssql_tunnel_host: "{{ tunnel_bastion | default('') }}"
mssql_tunnel_port: "{{ tunnel_local_port | default(mssql_port) }}"
```

This way any BU that uses a tunnel can enable it via inventory, without changing the role code.

### Step 5: Test Both Paths

```bash
# Test without tunnel (standard BUs)
ansible-playbook run_mssql_inspec.yml \
  -e "mssql_use_tunnel=false" \
  -i standard_bu_inventory.yml

# Test with tunnel (tunnel BU)
ansible-playbook run_mssql_inspec.yml \
  -e "mssql_use_tunnel=true" \
  -e "mssql_tunnel_host=[TUNNEL_HOST]" \
  -i tunnel_bu_inventory.yml
```

### Step 6: Create PR to Main

```bash
git push origin feature/mssql-scan
# Create PR: feature/mssql-scan -> main
```

Include in PR description:
- What was merged from colleague's branch
- What was parameterised vs taken as-is
- Which BU this was tested against

## If You Just Want a Straight Merge

If the colleague's code is already well-parameterised and you're happy with all changes:

```bash
git checkout feature/mssql-scan
git fetch origin
git merge origin/<colleague-branch-name>

# Resolve conflicts if any
git status
# Edit conflicting files, then:
git add <resolved-files>
git commit

# Push and create PR
git push origin feature/mssql-scan
```

## Handling Merge Conflicts

Common conflict areas for this scenario:

| File | Likely Conflict | Resolution |
|------|----------------|------------|
| `defaults/main.yml` | New tunnel variables added | Keep both sets of variables |
| `tasks/execute_direct.yml` | Modified connection logic | Merge carefully, ensure both paths work |
| `tasks/preflight.yml` | Changed connectivity checks | Keep generic checks, add tunnel option |
| Inventory files | BU-specific values | Keep in separate inventory, not in role |

### Conflict Resolution Commands

```bash
# See which files conflict
git status

# For each conflicting file, open and resolve manually
# Look for <<<<<<< ======= >>>>>>> markers

# After resolving
git add <file>
git commit
```

## Post-Merge Checklist

- [ ] No hardcoded BU names, hostnames, or IPs in role code
- [ ] Tunnel connectivity is optional (controlled by variable)
- [ ] Standard (non-tunnel) BUs still work without changes
- [ ] Inventory for tunnel BU uses variables, not inline values
- [ ] Tested against both tunnel and non-tunnel environments
