# Delegate Connection Test Playbook

## Purpose

This playbook (`test_delegate_connection.yml`) validates that the SSH connection fix for InSpec compliance scanning is working correctly. It should be run **before** executing any compliance scan playbooks to ensure the environment is properly configured.

## What It Tests

1. **SSH Connection** - Verifies Ansible can connect to the delegate host using SSH
2. **InSpec Installation** - Confirms InSpec is installed at `/usr/bin/inspec`
3. **MSSQL sqlcmd** - Checks if `sqlcmd` binary is accessible with proper PATH
4. **Oracle sqlplus** - Checks if `sqlplus` binary is accessible with ORACLE_HOME set
5. **Sybase isql** - Checks if `isql` binary is accessible with SYBASE environment
6. **Environment Variables** - Verifies environment variables propagate correctly
7. **InSpec Execution** - Simulates running InSpec with environment variables

## Running in AAP (Ansible Automation Platform)

### Step 1: Create Job Template

1. Log into AAP
2. Navigate to **Resources → Templates**
3. Click **Add → Add job template**
4. Configure:
   - **Name**: `Test Delegate Connection`
   - **Job Type**: Run
   - **Inventory**: Any valid inventory (it only runs on localhost)
   - **Project**: Your project containing this playbook
   - **Playbook**: `test_delegate_connection.yml`
   - **Credentials**: SSH credential for the delegate host
   - **Verbosity**: 1 (Verbose) or higher for detailed output

### Step 2: Configure Extra Variables (Optional)

Add your actual delegate host to **Extra Variables**:

```yaml
controller_delegate_host: "your-delegate-hostname"
```

### Step 3: Launch the Job

1. Click **Launch** on the job template
2. Monitor the output
3. Look for the **TEST SUMMARY** at the end

## Running in POC Mode (Command Line)

```bash
# Basic run
ansible-playbook test_delegate_connection.yml

# With custom delegate host
ansible-playbook test_delegate_connection.yml -e "controller_delegate_host=your-delegate-host"

# With verbose output
ansible-playbook test_delegate_connection.yml -v
```

## Expected Output

### Successful Run

```
================================================
TEST SUMMARY
================================================
Delegate Host: inspec-delegate-host
Connection Method: SSH

Tests Completed:
1. ✓ SSH/Local connection to delegate host
2. ✓ InSpec installation verification
3. ✓ MSSQL sqlcmd accessibility
4. ✓ Oracle sqlplus accessibility
5. ✓ Sybase isql accessibility
6. ✓ Environment variable propagation
7. ✓ InSpec execution with environment

================================================
✓✓✓ ALL TESTS PASSED ✓✓✓

The delegate host is properly configured!
You can now run the compliance scan playbooks:
- run_mssql_inspec.yml
- run_oracle_inspec.yml
- run_sybase_inspec.yml
================================================
```

### Failed Run Example

```
================================================
TEST SUMMARY
================================================
Delegate Host: inspec-delegate-host
Connection Method: SSH

Tests Completed:
1. ✓ SSH/Local connection to delegate host
2. ✓ InSpec installation verification
3. ✗ MSSQL sqlcmd accessibility
4. ✓ Oracle sqlplus accessibility
5. ✗ Sybase isql accessibility
6. ✓ Environment variable propagation
7. ✓ InSpec execution with environment

================================================
⚠ SOME TESTS FAILED ⚠

Please verify that database client tools are installed
at the expected locations on your delegate host
================================================
```

## Troubleshooting

### Test 1 Failed: SSH Connection

**Problem**: Cannot connect to delegate host

**Solutions**:
- Verify the delegate host is reachable: `ping your-delegate-host`
- Check SSH credentials are configured in AAP
- Ensure firewall allows SSH connections
- Verify the hostname is correct

### Test 2 Failed: InSpec Installation

**Problem**: InSpec not found at `/usr/bin/inspec`

**Solutions**:
- Install InSpec on delegate host: `gem install inspec`
- Verify InSpec location: `which inspec`
- Create symlink if needed: `ln -s /path/to/inspec /usr/bin/inspec`

### Test 3 Failed: MSSQL sqlcmd

**Problem**: sqlcmd binary not accessible

**Solutions**:
- Install MSSQL tools: `https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools`
- Verify installation: `ls -la /opt/mssql-tools/bin/sqlcmd`
- Check PATH in `mssql_inspec/vars/main.yml`

### Test 4 Failed: Oracle sqlplus

**Problem**: sqlplus binary not accessible

**Solutions**:
- Install Oracle Instant Client
- Set ORACLE_HOME correctly
- Verify installation: `ls -la $ORACLE_HOME/bin/sqlplus`
- Check ORACLE_HOME in `oracle_inspec/vars/main.yml`

### Test 5 Failed: Sybase isql

**Problem**: isql binary not accessible

**Solutions**:
- Install Sybase ASE client tools
- Set SYBASE environment variable correctly
- Verify installation: `ls -la $SYBASE/$SYBASE_OCS/bin/isql`
- Check SYBASE paths in `sybase_inspec/vars/main.yml`

## Environment Variables Tested

### MSSQL Environment
- `PATH`: `/opt/mssql-tools/bin:/tools/ver/sybase/OCS-16_0/bin:$PATH`
- `LD_LIBRARY_PATH`: `/tools/ver/oracle-19.16.0.0-64`

### Oracle Environment
- `PATH`: `/usr/local/oracle/BACKUP_FILES/mssql-tools/bin:/tools/ver/sybase/OCS-16_0/bin:$PATH`
- `LD_LIBRARY_PATH`: `/tools/ver/oracle-19.16.0.0-64`
- `ORACLE_HOME`: `/tools/ver/oracle-19.16.0.0-64`
- `TNS_ADMIN`: `/tools/ver/oracle-19.16.0.0-64/network/admin`

### Sybase Environment
- `PATH`: `/usr/local/oracle/BACKUP_FILES/mssql-tools/bin:/tools/ver/sybase/OCS-16_0/bin:$PATH`
- `LD_LIBRARY_PATH`: `/tools/ver/oracle-19.16.0.0-64:/tools/ver/sybase/OCS-16_0/lib`
- `SYBASE`: `/tools/ver/sybase`
- `SYBASE_OCS`: `OCS-16_0`

## Next Steps

### If All Tests Pass

You can safely run the compliance scan playbooks:

```bash
# MSSQL compliance scans
ansible-playbook -i inventory.yml run_mssql_inspec.yml

# Oracle compliance scans
ansible-playbook -i oracle_inventory.yml run_oracle_inspec.yml

# Sybase compliance scans
ansible-playbook -i sybase_inventory.yml run_sybase_inspec.yml
```

### If Any Tests Fail

1. Review the specific test failure messages
2. Follow the troubleshooting steps above
3. Fix the identified issues
4. Re-run this test playbook
5. Only proceed with compliance scans after all tests pass

## Files Modified by This Fix

This test validates the fixes applied to:

- `mssql_inspec/tasks/execute.yml`
- `mssql_inspec/tasks/setup.yml`
- `mssql_inspec/tasks/validate.yml`
- `oracle_inspec/tasks/execute.yml`
- `oracle_inspec/tasks/setup.yml`
- `oracle_inspec/tasks/validate.yml`
- `sybase_inspec/tasks/execute.yml`
- `sybase_inspec/tasks/setup.yml`
- `sybase_inspec/tasks/validate.yml`
- `sybase_inspec/tasks/ssh_setup.yml`

## Key Fix Implemented

All tasks that use `delegate_to` now include:

```yaml
vars:
  ansible_connection: "{{ 'local' if inspec_delegate_host == 'localhost' else 'ssh' }}"
```

This ensures:
- When delegate host is `localhost`, use local connection
- When delegate host is a remote server, use SSH connection
- InSpec runs on the delegate host with access to all database client binaries
- Environment variables are properly propagated to InSpec subprocesses
