# InSpec Role Fixes Summary

## Overview
Fixed critical issues with local execution mode, pre-flight validation, and error handling across all three InSpec roles (MSSQL, Oracle, Sybase).

## Key Changes

### 1. Local Execution Without SSH to Inventory Hosts
**Problem:** Roles were SSHing to inventory hosts during fact gathering, defeating the purpose of local execution.

**Solution:**
- Added `gather_facts: false` to all test playbooks
- Added `connection: local` to all test playbooks
- Implemented one-time controller facts gathering using `run_once` and `delegate_to: localhost`
- Unified all role execution to use `inspec_execution_target` variable (either delegate host or localhost)

**Files Modified:**
- `test_playbooks/test_mssql_localhost.yml`
- `test_playbooks/test_mssql_delegate.yml`
- `test_playbooks/run_mssql_inspec.yml`
- `test_playbooks/run_oracle_inspec.yml`
- `test_playbooks/run_sybase_inspec.yml`

### 2. Pre-Flight Tool Validation
**Problem:** Missing required database tools (sqlcmd, SQL*Plus, isql) were not detected, causing silent failures.

**Solution:** Added explicit validation tasks before InSpec execution:

#### MSSQL Role (`roles/mssql_inspec/tasks/execute.yml`)
```yaml
- name: Verify sqlcmd is available in PATH
  shell: |
    set -e
    echo "Checking for sqlcmd in PATH..."
    which sqlcmd > /dev/null 2>&1
    echo "OK sqlcmd is available"
  environment:
    PATH: "{{ mssql_environment.PATH }}"
  delegate_to: "{{ inspec_execution_target }}"
  changed_when: false
  register: sqlcmd_validation
  ignore_errors: true

- name: Fail if sqlcmd is not available
  fail:
    msg: "CRITICAL ERROR: sqlcmd not found in PATH. Install mssql-tools package."
  when: sqlcmd_validation is failed
```

#### Oracle Role (`roles/oracle_inspec/tasks/execute.yml`)
```yaml
- name: Verify SQL*Plus is available
  shell: |
    set -e
    echo "Checking for SQL*Plus..."
    which sqlplus > /dev/null 2>&1
    echo "OK SQL*Plus is available"
  environment:
    ORACLE_HOME: "{{ oracle_home }}"
    PATH: "{{ oracle_environment.PATH }}"
  delegate_to: "{{ inspec_execution_target }}"
  changed_when: false
  register: sqlplus_validation
  ignore_errors: true

- name: Fail if SQL*Plus is not available
  fail:
    msg: "CRITICAL ERROR: SQL*Plus not found. Install Oracle InstantClient..."
  when: sqlplus_validation is failed
```

#### Sybase Role (`roles/sybase_inspec/tasks/execute.yml`)
```yaml
- name: Verify isql is available in PATH
  shell: |
    set -e
    echo "Checking for isql in PATH..."
    which isql > /dev/null 2>&1
    echo "OK isql is available"
  environment:
    PATH: "{{ sybase_environment.PATH }}"
  delegate_to: "{{ inspec_execution_target }}"
  changed_when: false
  register: isql_validation
  ignore_errors: true

- name: Fail if isql is not available
  fail:
    msg: "CRITICAL ERROR: isql not found in PATH"
  when: isql_validation is failed
```

### 3. Proper Error Detection in InSpec Execution
**Problem:** Roles were silently passing when InSpec execution failed due to `failed_when: false`.

**Solution:** Implemented conditional error detection across all roles:

#### Pattern Applied to All Roles:
```yaml
failed_when: |
  (rc != 0 and 
   'Cannot connect' not in stdout and 
   'Unreachable' not in stdout)
```

**Logic:**
- Task fails if return code is non-zero AND
- Output does NOT contain connection error messages (captured for JSON reporting)
- This allows connection timeouts to be captured in JSON results without failing the task
- But fails on actual tool/syntax/execution errors

**Applied to:**
- `roles/mssql_inspec/tasks/execute.yml` - InSpec execution task
- `roles/oracle_inspec/tasks/execute.yml` - InSpec execution task
- `roles/sybase_inspec/tasks/execute.yml` - Both SSH and direct execution tasks

### 4. Environment Variable Management
**Issue:** Environment variables for database tools weren't properly inherited.

**Solution:** 
- Built complete environment variable sets with all necessary paths
- Variables passed through `environment:` in all shell tasks
- Each role maintains its own environment dict with base paths + runtime paths

**Example (MSSQL):**
```yaml
mssql_environment:
  PATH: "{{ mssql_environment_base.PATH }}:{{ _target_env.PATH }}"
  SQLCMDPASSWORD: "{{ mssql_password }}"
  SQLCMDUSER: "{{ mssql_username }}"
```

### 5. Removed Unsupported Ansible Constructs
**Issue:** `include_tasks` with `delegate_to` is not supported in Ansible.

**Solution:**
- Removed all `delegate_to` from `include_tasks` calls
- Moved delegation to tasks within included files
- Used `inspec_execution_target` variable for consistent delegation

**Files Modified:**
- All roles' main.yml and result processing files
- Splunk integration includes refactored to not use delegate_to

### 6. Test Playbook Updates
**Added Pre-Flight Checks in Test Playbooks:**

All test playbooks now check for required tools before invoking roles:

```yaml
- name: Verify sqlcmd is available before running InSpec role
  shell: |
    which sqlcmd > /dev/null 2>&1 && echo "sqlcmd found" || {
      echo "ERROR: sqlcmd not found in PATH"
      echo "Install with: apt-get install mssql-tools"
      exit 1
    }
  changed_when: false
  delegate_to: localhost
  run_once: true
```

## Verification Checklist

- [x] MSSQL role: sqlcmd validation before execution
- [x] MSSQL role: proper error detection (fails on real errors, captures connection timeouts)
- [x] Oracle role: SQL*Plus validation before execution
- [x] Oracle role: proper error detection
- [x] Sybase role: isql validation before execution
- [x] Sybase role: proper error detection (both SSH and direct modes)
- [x] All test playbooks: controller-only fact gathering
- [x] All test playbooks: `gather_facts: false`
- [x] All test playbooks: `connection: local`
- [x] All roles: unified execution target via `inspec_execution_target`
- [x] All roles: environment variables properly inherited from execution target

## Testing Instructions

### Test 1: Verify Pre-Flight Checks Work
```bash
cd /Users/shola/Documents/MyGoProject/linux-inspec

# Test MSSQL tool validation
ansible-playbook test_playbooks/test_mssql_localhost.yml

# Expected: Fails with "sqlcmd not found" if mssql-tools not installed
```

### Test 2: Verify Error Handling
Run with a non-existent database host and confirm:
- Connection errors are captured in JSON output
- Task does NOT fail (allows results to be processed)
- Error messages are clear and actionable

### Test 3: Verify No SSH to Inventory Hosts
```bash
# Add verbose output and watch SSH connections
ansible-playbook -vvv test_playbooks/run_mssql_inspec.yml

# Should see only "localhost" in connection info, no SSH to actual database hosts
```

## Environment Variables Required

### For MSSQL
```bash
export MSSQL_SA_PASSWORD="your_password"
export PATH="/opt/mssql-tools/bin:$PATH"
```

### For Oracle
```bash
export ORACLE_HOME="/opt/oracle-ic"
export TNS_ADMIN="$ORACLE_HOME/network/admin"
export LD_LIBRARY_PATH="$ORACLE_HOME/lib:$LD_LIBRARY_PATH"
export PATH="$ORACLE_HOME/bin:$PATH"
```

### For Sybase
```bash
export SYBASE="/opt/sybase"
export SYBASE_OCS="OCS-16_0"
export PATH="$SYBASE/bin:$PATH"
export LD_LIBRARY_PATH="$SYBASE/lib:$LD_LIBRARY_PATH"
```

## Files Changed Summary

| File | Changes |
|------|---------|
| `roles/mssql_inspec/tasks/execute.yml` | Added sqlcmd validation, fixed error handling |
| `roles/oracle_inspec/tasks/execute.yml` | Added SQL*Plus validation, fixed error handling |
| `roles/sybase_inspec/tasks/execute.yml` | Added isql validation, fixed error handling for both execution modes |
| `test_playbooks/test_mssql_localhost.yml` | Added sqlcmd check, local execution setup |
| `test_playbooks/test_mssql_delegate.yml` | Added sqlcmd check, local execution setup |
| `test_playbooks/run_mssql_inspec.yml` | Controller facts gathering, local execution |
| `test_playbooks/run_oracle_inspec.yml` | Controller facts gathering, local execution |
| `test_playbooks/run_sybase_inspec.yml` | Controller facts gathering, local execution |

## Next Steps

1. Install required database tools in execution environment
2. Run test playbooks to verify setup works
3. Review JSON output format to ensure results are properly captured
4. Configure Splunk integration (currently disabled in roles)
5. Set up production playbooks for regular scanning
