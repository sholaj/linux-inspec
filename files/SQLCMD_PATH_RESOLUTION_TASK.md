# SQLCMD PATH Resolution Task

## Problem Statement

When executing MSSQL InSpec compliance scans through Ansible Automation Platform 2 (AAP2), the InSpec controls fail with the error `"sqlcmd: command not found"` even though the `sqlcmd` binary is installed and accessible when running commands manually on the delegate host.

### Error Messages Observed

```
"Could not execute the sql query \\nsh: sqlcmd: command not found"
"/bin/bash: line 3: which: command not found"
```

### Environment

| Component | Details |
|-----------|---------|
| **Platform** | Ansible Automation Platform 2 (AAP2) |
| **Delegate Host** | `<DELEGATE_HOST>` |
| **Database Targets** | MSSQL servers (`<MSSQL_SERVER_1>`, `<MSSQL_SERVER_2>`) |
| **InSpec Location** | /usr/bin/inspec |
| **sqlcmd Location** | /opt/mssql-tools/bin/sqlcmd |
| **Connection Type** | ansible_connection: local |

---

## Root Cause

1. **Ansible `environment` directive** sets variables at the task level but InSpec's `mssql_session` spawns a subprocess that doesn't inherit these variables
2. **AAP2 execution environments** use a minimal PATH that doesn't include standard utility locations
3. **InSpec `mssql_session` resource** has no `sqlcmd_bin` parameter - it expects `sqlcmd` in PATH

---

## Task Objectives

1. ✅ Verify sqlcmd is present on the delegate host
2. ✅ Diagnose the PATH inheritance issue
3. ✅ Implement a permanent fix
4. ✅ Validate the solution works in AAP2

---

## Step 1: Diagnostic Playbook

Run `diagnose_sqlcmd_path.yml` to verify the environment:

```bash
ansible-playbook -i inventory.yml diagnose_sqlcmd_path.yml -e "inspec_delegate_host=<DELEGATE_HOST>"
```

### Expected Output

The playbook will show:
- Whether sqlcmd exists at expected locations
- Current PATH in different execution contexts
- Whether InSpec can find sqlcmd

---

## Step 2: Apply the Fix

The fix involves exporting PATH **inside** the shell command block so all child processes (including InSpec's Ruby subprocess) inherit the correct PATH.

### Before (Broken)

```yaml
- name: Execute InSpec controls
  shell: |
    /usr/bin/inspec exec {{ item.path }} ...
  environment:
    PATH: "{{ mssql_environment.PATH }}"  # NOT inherited by subprocesses!
```

### After (Fixed)

```yaml
- name: Execute InSpec controls
  shell: |
    export PATH=/opt/mssql-tools/bin:/tools/ver/sybase/OCS-16_0/bin:/usr/local/bin:/usr/bin:/bin:$PATH
    export LD_LIBRARY_PATH=/tools/ver/oracle-19.16.0.0-64
    /usr/bin/inspec exec {{ item.path }} ...
```

---

## Step 3: Validate the Fix

Run `validate_sqlcmd_fix.yml` to confirm the solution:

```bash
ansible-playbook -i inventory.yml validate_sqlcmd_fix.yml -e "inspec_delegate_host=<DELEGATE_HOST>"
```

---

## Files Included

| File | Purpose |
|------|---------|
| `diagnose_sqlcmd_path.yml` | Diagnostic playbook to identify PATH issues |
| `validate_sqlcmd_fix.yml` | Validation playbook to confirm the fix works |
| `execute_fixed.yml` | Fixed execute.yml for mssql_inspec role |
| `mssql_environment_vars.yml` | Centralized environment variable definitions |

---

## Permanent Solution Options

### Option A: Export in Shell Block (Recommended)

Include PATH export directly in the shell command. This is the most reliable approach as it guarantees child processes inherit the PATH.

### Option B: Create System Symlink (One-time Setup)

Create a symlink on the delegate host so sqlcmd is globally available:

```bash
sudo ln -s /opt/mssql-tools/bin/sqlcmd /usr/local/bin/sqlcmd
```

### Option C: Modify /etc/environment (System-wide)

Add to `/etc/environment` on the delegate host:

```
PATH="/opt/mssql-tools/bin:/tools/ver/sybase/OCS-16_0/bin:/usr/local/bin:/usr/bin:/bin"
```

---

## Implementation Checklist

- [ ] Run diagnostic playbook to confirm sqlcmd location
- [ ] Update `execute.yml` with PATH export in shell block
- [ ] Remove debug commands (`env`, `which`) that fail in minimal environments
- [ ] Test with single database target
- [ ] Validate full scan execution in AAP2
- [ ] Update documentation

---

## Notes

- **Do NOT delete** `ansible_connection: local` from inventory - this is correct for database endpoint scanning
- The delegate host is where InSpec runs; database hosts are network endpoints only
- AAP2 credential injection for `mssql_password` works correctly via Survey or Custom Credential Type
