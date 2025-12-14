# Quick Start: Updated InSpec Roles

## What Changed

All three InSpec roles (MSSQL, Oracle, Sybase) have been updated to:

1. **Run locally** without SSH to database inventory hosts
2. **Validate required tools** exist before execution  
3. **Properly detect errors** instead of silently failing
4. **Use unified execution targets** for consistent behavior

## Pre-Requisites

### On Your AAP2/Local Execution Environment

#### For MSSQL Scanning
```bash
# Install mssql-tools
apt-get update && apt-get install -y mssql-tools

# Verify installation
which sqlcmd
sqlcmd -?
```

#### For Oracle Scanning
```bash
# Download and install Oracle InstantClient
# https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html

# Extract to /opt/oracle-ic
mkdir -p /opt/oracle-ic
cd /opt/oracle-ic
unzip instantclient-*.zip

# Set environment variables
export ORACLE_HOME=/opt/oracle-ic
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH

# Verify installation
which sqlplus
sqlplus -version
```

#### For Sybase Scanning
```bash
# Install Sybase tools (varies by platform)
# For Linux: Install from Sybase ASE client package

# Verify installation
which isql
isql -v
```

## Running Scans

### Example 1: Local MSSQL Scan
```yaml
---
- name: Run MSSQL InSpec Scan
  hosts: localhost
  connection: local
  gather_facts: false
  
  vars:
    mssql_server: "your-mssql-server.example.com"
    mssql_port: 1433
    mssql_username: "scan_user"
    mssql_password: "your_password"
    
  roles:
    - mssql_inspec
```

### Example 2: Local Oracle Scan
```yaml
---
- name: Run Oracle InSpec Scan
  hosts: localhost
  connection: local
  gather_facts: false
  
  vars:
    oracle_server: "your-oracle-server.example.com"
    oracle_port: 1521
    oracle_service: "ORCL"
    oracle_username: "scan_user"
    oracle_password: "your_password"
    
    # Required for Oracle
    oracle_home: "/opt/oracle-ic"
    
  roles:
    - oracle_inspec
```

### Example 3: Local Sybase Scan
```yaml
---
- name: Run Sybase InSpec Scan
  hosts: localhost
  connection: local
  gather_facts: false
  
  vars:
    sybase_server: "your-sybase-server.example.com"
    sybase_port: 5000
    sybase_username: "scan_user"
    sybase_password: "your_password"
    
  roles:
    - sybase_inspec
```

## How It Works Now

### Before (Old Implementation)
```
Playbook runs
  ↓
AAP2 SSHs to inventory host (database)
  ↓
Role executes
  ↓
InSpec runs (with or without SSH)
  ↓
Fails silently (failed_when: false)
```

### After (New Implementation)
```
Playbook runs on AAP2 (connection: local)
  ↓
Role gathers facts from AAP2 only (no SSH to DB)
  ↓
Role validates required tools exist
  ├─ If missing → FAIL with clear error message
  └─ If present → Continue
  ↓
InSpec runs on AAP2 with SSH to database
  ↓
Proper error detection
  ├─ Real errors → Task fails
  └─ Connection timeouts → Captured in JSON
  ↓
Results processed and reported
```

## Error Messages

### Tool Not Found
```
CRITICAL ERROR: sqlcmd not found in PATH
Install with: apt-get install mssql-tools
```

Solution: Install the required database tools in your execution environment.

### Connection Timeout
```
JSON Result: {
  "status": "failed",
  "error": "Cannot connect to MSSQL server at host:port"
}
```

Solution: Verify database is accessible from AAP2 execution node.

### InSpec Execution Error
```
Task failed
Exit Code: 1
Message: InSpec execution failed (real error detected)
```

Solution: Check InSpec control syntax and database configuration.

## Testing Your Setup

### Test 1: Verify Tools Are Installed
```bash
# For MSSQL
which sqlcmd && echo "✓ sqlcmd is available"

# For Oracle
which sqlplus && echo "✓ sqlplus is available"

# For Sybase
which isql && echo "✓ isql is available"
```

### Test 2: Run Pre-Flight Checks
```bash
# MSSQL
ansible-playbook test_playbooks/test_mssql_localhost.yml -v

# Oracle
ansible-playbook test_playbooks/run_oracle_inspec.yml -v

# Sybase
ansible-playbook test_playbooks/run_sybase_inspec.yml -v
```

### Test 3: Verify No SSH to Database
```bash
# Run with verbose output and check connections
ansible-playbook test_playbooks/run_mssql_inspec.yml -vvv | grep -i "ssh\|connect"

# Should only show localhost connections, not to database servers
```

## Key Features

✓ **Local Execution** - No SSH to database inventory hosts  
✓ **Pre-Flight Checks** - Validates required tools before scanning  
✓ **Proper Error Detection** - Fails on real errors, captures connection timeouts  
✓ **Unified Targets** - Consistent behavior across all execution modes  
✓ **Environment Isolation** - Each role manages its own environment variables  
✓ **Clear Error Messages** - Actionable failure messages with remediation steps  

## Troubleshooting

### Issue: "sqlcmd not found in PATH"
**Solution:** Install mssql-tools and ensure /opt/mssql-tools/bin is in PATH
```bash
apt-get install mssql-tools
export PATH=/opt/mssql-tools/bin:$PATH
```

### Issue: "Cannot connect to database"
**Solution:** Verify network connectivity from AAP2 execution node
```bash
# Test connectivity
telnet your-database-server.example.com 1433
# or
nc -zv your-database-server.example.com 1433
```

### Issue: "No such file or directory" for InSpec controls
**Solution:** Verify control files exist in the expected location
```bash
ls -la roles/*/files/controls/
```

### Issue: "Permission denied" errors
**Solution:** Ensure AAP2 execution user has permissions to read control files
```bash
chmod -R 755 roles/*/files/
```

## Validation

Run the included validation script to verify all changes are in place:
```bash
./validate_fixes.sh
```

Expected output: All 19 checks should PASS

## Support

For issues or questions:
1. Check the error messages for clear remediation steps
2. Review the FIXES_SUMMARY.md for technical details
3. Validate setup with validate_fixes.sh
4. Check Ansible debug output with -vvv flag
