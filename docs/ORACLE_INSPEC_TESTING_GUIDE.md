# Oracle InSpec Testing Guide

A comprehensive step-by-step guide for testing Oracle database compliance using Chef InSpec.

**Last Updated:** January 2026
**InSpec Version:** 5.22+
**Oracle Versions Supported:** 11g, 12c, 18c, 19c

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Understanding the oracledb_session Resource](#understanding-the-oracledb_session-resource)
3. [Repository Structure](#repository-structure)
4. [Testing Workflow](#testing-workflow)
5. [Running the Tests](#running-the-tests)
6. [Expected Output Examples](#expected-output-examples)
7. [Troubleshooting](#troubleshooting)
8. [Reference: Existing Scripts and Playbooks](#reference-existing-scripts-and-playbooks)

---

## Prerequisites

Before running Oracle InSpec tests, ensure the following requirements are met.

### 1. Infrastructure Requirements

| Component | Requirement | How to Verify |
|-----------|-------------|---------------|
| Runner VM | Linux with network access to Oracle | SSH to runner VM |
| InSpec | Version 5.22+ installed | `inspec version` |
| Oracle Instant Client | With sqlplus binary | `which sqlplus && sqlplus -V` |
| Network Access | Port 1521 open to Oracle server | `timeout 5 bash -c 'cat < /dev/null > /dev/tcp/<ORACLE_HOST>/1521'` |

### 2. Oracle Client Installation

The Oracle Instant Client must be installed on the runner/delegate host. Typical installation paths:

```bash
# RHEL/CentOS location (yum install)
/usr/lib/oracle/21/client64/bin/sqlplus

# Manual install location (common)
/opt/oracle/instantclient_19_16/sqlplus
```

### 3. Required Environment Variables

Set these environment variables before running tests:

```bash
# Oracle client paths
export ORACLE_HOME=/usr/lib/oracle/21/client64
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME/bin:$PATH

# Optional: For TNS connections
export TNS_ADMIN=/path/to/tns/admin

# Character set
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
```

### 4. Database Credentials

You need valid Oracle database credentials with sufficient privileges to query:
- `v$parameter` (system parameters)
- `v$version` (version info)
- `dba_profiles` (password policies)
- `dba_users` (user information)
- `dba_role_privs` (role assignments)
- `dba_sys_privs` (system privileges)
- `dba_tab_privs` (table privileges)

Recommended: Use a dedicated `nist_scan_user` account with SELECT privileges on these views.

---

## Understanding the oracledb_session Resource

The `oracledb_session` resource is Chef InSpec's native resource for querying Oracle databases.

### Resource Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `user` | Yes | - | Oracle username |
| `password` | Yes | - | Oracle password |
| `host` | No | localhost | Database server hostname/IP |
| `port` | No | 1521 | Oracle listener port |
| `service` | No | - | Oracle service name (preferred) |
| `sid` | No | - | Oracle SID (legacy) |
| `sqlplus_bin` | No | sqlplus | Path to sqlplus binary |
| `as_db_role` | No | - | Connect as sysdba/sysoper/sysasm |
| `as_os_user` | No | - | OS user for authentication |

### Basic Usage Pattern

```ruby
# Create database session
sql = oracledb_session(
  user: 'system',
  password: 'OraclePass123',
  host: '10.0.2.6',
  port: 1521,
  service: 'ORCLCDB'
)

# Query and test results
control 'oracle-example' do
  impact 1.0
  title 'Example Oracle Control'

  describe sql.query("SELECT value FROM v$parameter WHERE name = 'audit_trail'").row(0).column('value') do
    its('value') { should_not cmp 'NONE' }
  end
end
```

### Query Result Methods

| Method | Returns | Example |
|--------|---------|---------|
| `.query(sql)` | Result set | `sql.query("SELECT * FROM dual")` |
| `.row(n)` | Single row (0-indexed) | `.query(...).row(0)` |
| `.column(name)` | Column values as array | `.query(...).column('VALUE')` |
| `.rows` | All rows as array | `.query(...).rows` |

### Connection String Format

The resource uses Easy Connect format internally:

```
sqlplus user/password@//host:port/service_name
```

Example:
```
sqlplus system/OraclePass123@//10.0.2.6:1521/ORCLCDB
```

---

## Repository Structure

The Oracle InSpec testing components are organized as follows:

```
linux-inspec/
|
+-- roles/oracle_inspec/           # Ansible role for Oracle scanning
|   +-- tasks/
|   |   +-- main.yml               # Entry point - orchestrates scan
|   |   +-- validate.yml           # Validates connection parameters
|   |   +-- preflight.yml          # Pre-scan connectivity checks
|   |   +-- setup.yml              # Creates directories, finds controls
|   |   +-- execute.yml            # Runs InSpec controls
|   |   +-- process_results.yml    # Saves JSON results
|   |   +-- cleanup.yml            # Generates reports, cleanup
|   |
|   +-- defaults/main.yml          # Default variable values
|   +-- vars/main.yml              # Tool paths, templates
|   +-- files/
|   |   +-- ORACLE19c_ruby/        # Oracle 19c controls
|   |       +-- controls/trusted.rb
|   |       +-- inspec.yml
|   +-- templates/
|       +-- oracle_summary_report.j2
|
+-- test_playbooks/
|   +-- run_oracle_inspec.yml       # Main Oracle scanning playbook
|   +-- test_oracle_connectivity.yml # Connectivity test playbook
|
+-- scripts/
|   +-- test-oracle-connectivity.sh      # Bash connectivity tests
|   +-- test-oracle-connectivity-password.sh  # Password-based SSH version
|
+-- inventories/
    +-- hosts.yml                   # Inventory with Oracle database entries
```

---

## Testing Workflow

Follow this workflow to test Oracle compliance:

```
Step 1: Verify Prerequisites
        |
        v
Step 2: Test Network Connectivity (Port 1521)
        |
        v
Step 3: Test Database Authentication
        |
        v
Step 4: Run Connectivity Test Script
        |
        v
Step 5: Run InSpec Controls (via Playbook or Direct)
        |
        v
Step 6: Review Results (JSON files in /tmp/compliance_scans/)
```

---

## Running the Tests

### Method 1: Direct InSpec Execution (Recommended for Testing)

SSH to the runner VM and execute InSpec directly.

#### Step 1: SSH to Runner VM

```bash
ssh -i ~/.ssh/inspec_rsa azureuser@<RUNNER_IP>
```

#### Step 2: Set Environment Variables

```bash
export ORACLE_HOME=/usr/lib/oracle/21/client64
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME/bin:$PATH
```

#### Step 3: Test Connectivity

```bash
# Test port
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/10.0.2.6/1521' && echo "Port OPEN" || echo "Port CLOSED"

# Test credentials
sqlplus -S system/OraclePass123@//10.0.2.6:1521/ORCLCDB << 'EOF'
SET HEADING OFF FEEDBACK OFF
SELECT 'CONNECTION_OK' FROM DUAL;
EXIT;
EOF
```

#### Step 4: Run InSpec Profile

```bash
# Navigate to the InSpec profile
cd /path/to/linux-inspec/roles/oracle_inspec/files/ORACLE19c_ruby

# Execute with inputs
inspec exec . \
  --input usernm=system \
           passwd=OraclePass123 \
           hostnm=10.0.2.6 \
           port=1521 \
           servicenm=ORCLCDB \
  --reporter cli json:/tmp/oracle_results.json
```

### Method 2: Using the Connectivity Test Script

From your local machine (with SSH access to runner):

```bash
cd /path/to/linux-inspec

# Set environment variables
export RUNNER_HOST=52.170.28.135
export SSH_KEY=~/.ssh/inspec_rsa
export ORACLE_SERVER=10.0.2.6
export ORACLE_PORT=1521
export ORACLE_SERVICE=ORCLCDB
export ORACLE_PASSWORD=OraclePass123

# Run the script
./scripts/test-oracle-connectivity.sh
```

### Method 3: Using Ansible Playbook

When Ansible is installed on the runner:

```bash
# From the runner VM
cd /home/azureuser/linux-inspec

# Run the Oracle InSpec playbook
ansible-playbook test_playbooks/run_oracle_inspec.yml \
  -i inventories/hosts.yml \
  -e "enable_debug=true"
```

Alternatively, run the connectivity test playbook:

```bash
ansible-playbook test_playbooks/test_oracle_connectivity.yml
```

---

## Expected Output Examples

### Successful InSpec Execution

```
Profile:   CIS Oracle Database 19c Compliance (oracle-19c-cis)
Version:   1.0.0
Target:    local://
Target ID: f9809200-f9b3-5d33-ab79-8f6fbad928ed

  [PASS]  oracle-test-01: Oracle Basic Connectivity Test
     [PASS]  SQL Column value is expected to cmp == "INSPEC_TEST_SUCCESS"
  [PASS]  oracle-test-02: Oracle Version Check
     [PASS]  SQL Column value is expected to match /Oracle/
  [FAIL]  oracle-test-03: Oracle Audit Trail Check
     [FAIL]  SQL Column value is expected not to cmp == "NONE"

     expected: NONE
          got: NONE

  [PASS]  oracle-test-04: Remote OS Authentication Check
     [PASS]  SQL Column value is expected to cmp == "FALSE"
  [PASS]  oracle-test-05: Password Life Time Check
     [PASS]  SQL Column value is expected not to cmp == "UNLIMITED"


Profile Summary: 4 successful controls, 1 control failure, 0 controls skipped
Test Summary: 4 successful, 1 failure, 0 skipped
```

### JSON Output Structure

```json
{
  "platform": {
    "name": "redhat",
    "release": "8.10",
    "target_id": "f9809200-f9b3-5d33-ab79-8f6fbad928ed"
  },
  "profiles": [{
    "name": "oracle-19c-cis",
    "version": "1.0.0",
    "controls": [{
      "id": "oracle-19c-01",
      "title": "Ensure Oracle audit trail is enabled",
      "impact": 1.0,
      "results": [{
        "status": "passed",
        "code_desc": "SQL Column value...",
        "run_time": 0.123
      }]
    }]
  }],
  "statistics": {
    "duration": 0.456
  },
  "version": "5.22.29"
}
```

### Connectivity Test Output

```
========================================
Oracle Connectivity Test Suite
========================================

[TEST] Connecting to runner host: 52.170.28.135
[PASS] SSH connectivity to runner

[TEST] Testing telnet to Oracle: 10.0.2.6:1521
[PASS] Oracle port 1521 is reachable on 10.0.2.6

[TEST] Testing Oracle credentials with sqlplus
[PASS] Oracle database credentials validated
CONNECTION_SUCCESSFUL

[INFO] Oracle connectivity tests completed
```

---

## Troubleshooting

### Issue 1: sqlplus Not Found

**Symptom:**
```
bash: sqlplus: command not found
```

**Solution:**
```bash
# Find sqlplus location
sudo find / -name "sqlplus" 2>/dev/null

# Set ORACLE_HOME to correct path
export ORACLE_HOME=/path/to/instantclient
export PATH=$ORACLE_HOME:$PATH
```

### Issue 2: ORA-12541: TNS:no listener

**Symptom:**
```
ORA-12541: TNS:no listener
```

**Cause:** Oracle listener is not running on the target server or firewall is blocking.

**Solution:**
1. Verify port connectivity: `timeout 5 bash -c 'cat < /dev/null > /dev/tcp/<HOST>/1521'`
2. Check firewall rules allow port 1521
3. Verify Oracle listener is running on target: `lsnrctl status`

### Issue 3: ORA-01017: invalid username/password

**Symptom:**
```
ORA-01017: invalid username/password; logon denied
```

**Solution:**
1. Verify username and password are correct
2. Check account is not locked: `SELECT account_status FROM dba_users WHERE username = 'SYSTEM';`
3. Verify connection string format is correct

### Issue 4: ORA-12514: TNS:listener does not currently know of service

**Symptom:**
```
ORA-12514: TNS:listener does not currently know of service requested in connect descriptor
```

**Solution:**
1. Verify service name is correct: `lsnrctl services`
2. Use SID instead of service name if needed
3. Check for typos in service name

### Issue 5: Library Loading Errors

**Symptom:**
```
sqlplus: error while loading shared libraries: libclntsh.so.19.1
```

**Solution:**
```bash
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH

# Or for permanent fix
echo "$ORACLE_HOME/lib" | sudo tee /etc/ld.so.conf.d/oracle.conf
sudo ldconfig
```

### Issue 6: InSpec Control Not Executing

**Symptom:**
```
No tests executed.
Test Summary: 0 successful, 0 failures, 0 skipped
```

**Solution:**
1. Verify control files exist: `ls -la controls/*.rb`
2. Check inspec.yml is valid: `inspec check .`
3. Verify Ruby syntax: `ruby -c controls/trusted.rb`

### Issue 7: Column Name Case Sensitivity

**Symptom:**
```
undefined method 'value' for nil:NilClass
```

**Cause:** Oracle returns column names in UPPERCASE by default.

**Solution:** Use uppercase column names in `.column()`:
```ruby
# Wrong
.column('value')

# Correct
.column('VALUE')
```

---

## Reference: Existing Scripts and Playbooks

### Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/test-oracle-connectivity.sh` | Tests SSH, port, credentials, and basic InSpec | `./scripts/test-oracle-connectivity.sh` |
| `scripts/test-oracle-connectivity-password.sh` | Same as above but uses SSH password (requires sshpass) | `SSH_PASSWORD=xxx ./scripts/test-oracle-connectivity-password.sh` |

### Playbooks

| Playbook | Purpose | Command |
|----------|---------|---------|
| `test_playbooks/run_oracle_inspec.yml` | Full Oracle InSpec scan with all controls | `ansible-playbook test_playbooks/run_oracle_inspec.yml -i inventories/hosts.yml` |
| `test_playbooks/test_oracle_connectivity.yml` | Tests connectivity before full scan | `ansible-playbook test_playbooks/test_oracle_connectivity.yml` |

### Inventory Configuration

The Oracle databases are defined in `inventories/hosts.yml`:

```yaml
oracle_databases:
  hosts:
    oracle_test_01:
      oracle_server: 10.0.2.6
      oracle_port: 1521
      oracle_service: ORCLCDB
      oracle_database: ORCLCDB
      oracle_version: "19c"
      oracle_username: system
      oracle_password: "{{ lookup('env', 'ORACLE_PASSWORD') | default('OraclePass123', true) }}"
```

### Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `oracle_server` | - | Oracle server hostname/IP |
| `oracle_port` | 1521 | Listener port |
| `oracle_service` | - | Service name |
| `oracle_database` | - | Database name |
| `oracle_version` | 19c | Oracle version (11g, 12c, 18c, 19c) |
| `oracle_username` | nist_scan_user | Database username |
| `oracle_password` | - | Database password (use vault or env var) |
| `inspec_delegate_host` | localhost | Where InSpec runs (localhost or remote host) |
| `base_results_dir` | /tmp/compliance_scans | Where results are saved |
| `inspec_debug_mode` | false | Enable verbose output |

---

## Quick Reference Commands

```bash
# 1. SSH to runner
ssh -i ~/.ssh/inspec_rsa azureuser@<RUNNER_IP>

# 2. Set Oracle environment
export ORACLE_HOME=/usr/lib/oracle/21/client64
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME/bin:$PATH

# 3. Test connectivity
sqlplus -S system/OraclePass123@//10.0.2.6:1521/ORCLCDB << EOF
SELECT 'OK' FROM DUAL;
EXIT;
EOF

# 4. Run InSpec
inspec exec /path/to/ORACLE19c_ruby \
  --input usernm=system passwd=OraclePass123 hostnm=10.0.2.6 port=1521 servicenm=ORCLCDB \
  --reporter cli json:/tmp/results.json

# 5. View results
cat /tmp/results.json | python3 -m json.tool
```

---

## Additional Resources

- [Chef InSpec oracledb_session Documentation](https://docs.chef.io/inspec/7.0/resources/core/oracledb_session/)
- [Oracle Instant Client Downloads](https://www.oracle.com/database/technologies/instant-client/downloads.html)
- [CIS Oracle Database Benchmarks](https://www.cisecurity.org/benchmark/oracle_database)
- Role README: `/roles/oracle_inspec/README.md`
- CLAUDE.md (project runbook): `/CLAUDE.md`

---

*This guide was created for junior engineers testing Oracle database compliance in the Azure InSpec environment.*
