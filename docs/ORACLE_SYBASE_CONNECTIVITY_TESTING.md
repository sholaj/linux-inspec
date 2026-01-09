# Oracle and Sybase Connectivity Testing Guide

This guide provides step-by-step instructions for testing Oracle and Sybase database connectivity, including telnet tests, credential validation, and basic InSpec command execution.

## Prerequisites

### On Control Node (Local Machine)
- `ansible` >= 2.9
- SSH access to runner host (Azure VM)
- SSH private key file at `~/.ssh/inspec_azure` or configured via environment variable

### On Runner Host (Azure VM)
- Oracle Instant Client 19c with sqlplus installed
- FreeTDS with tsql installed
- InSpec CLI installed
- Python 3.6+ with Python interpreter at `/usr/bin/python3`

## Test Infrastructure

### Test Databases

| Database | Host | Port | Service | Version |
|----------|------|------|---------|---------|
| Oracle   | 10.0.2.5 | 1521 | ORCLCDB | 19c |
| Sybase   | 10.0.2.6 | 5000 | - | 16 |

### Runner Host

| Attribute | Value |
|-----------|-------|
| Public IP | 40.114.45.75 |
| Username | azureuser |
| SSH Key | ~/.ssh/inspec_azure |

## Running Tests

### Option 1: Ansible Playbook (Recommended)

Run the comprehensive test playbook:

```bash
# Run with default configuration
ansible-playbook test_playbooks/test_oracle_sybase_connectivity.yml

# Run with custom variables
ansible-playbook test_playbooks/test_oracle_sybase_connectivity.yml \
  -e "runner_host=<IP>" \
  -e "oracle_server=<IP>" \
  -e "sybase_server=<IP>"

# Run with verbose output
ansible-playbook test_playbooks/test_oracle_sybase_connectivity.yml -vv
```

### Option 2: Shell Script

Run the bash script on the control node:

```bash
# Make script executable
chmod +x scripts/test-oracle-sybase-connectivity.sh

# Run with default configuration
./scripts/test-oracle-sybase-connectivity.sh

# Run with custom environment variables
export RUNNER_HOST=40.114.45.75
export RUNNER_USER=azureuser
export SSH_KEY=~/.ssh/inspec_azure
export ORACLE_SERVER=10.0.2.5
export ORACLE_PORT=1521
export ORACLE_SERVICE=ORCLCDB
export ORACLE_USERNAME=system
export ORACLE_PASSWORD=OraclePass123
export SYBASE_SERVER=10.0.2.6
export SYBASE_PORT=5000
export SYBASE_USERNAME=sa
export SYBASE_PASSWORD=SybasePass123

./scripts/test-oracle-sybase-connectivity.sh
```

## Test Coverage

### Test 1: SSH Connectivity to Runner
**Purpose:** Validate SSH connectivity from control node to runner host  
**Command:** `ssh -i ~/.ssh/inspec_azure azureuser@40.114.45.75 "echo OK"`  
**Expected:** SSH connection successful

### Test 2: Oracle Telnet Port Connectivity
**Purpose:** Test TCP port 1521 reachability on Oracle server  
**Command:** `telnet 10.0.2.5 1521`  
**Expected:** Port is open and accepting connections

### Test 3: Oracle Credential Validation
**Purpose:** Verify Oracle database authentication with provided credentials  
**Command:** `sqlplus system/OraclePass123@//10.0.2.5:1521/ORCLCDB`  
**Expected:** Successful login and basic query execution

### Test 4: Sybase Telnet Port Connectivity
**Purpose:** Test TCP port 5000 reachability on Sybase server  
**Command:** `telnet 10.0.2.6 5000`  
**Expected:** Port is open and accepting connections

### Test 5: Sybase Credential Validation
**Purpose:** Verify Sybase database authentication with provided credentials  
**Command:** `tsql -S 10.0.2.6 -U sa -P SybasePass123`  
**Expected:** Successful login and basic query execution

### Test 6: Oracle InSpec Control Execution
**Purpose:** Execute a simple InSpec control against Oracle database  
**Control:** oracle-version-check  
**Expected:** InSpec control executes successfully and queries database version

### Test 7: Sybase InSpec Control Execution
**Purpose:** Execute a simple InSpec control against Sybase database  
**Control:** sybase-version-check  
**Expected:** InSpec control executes successfully and queries database version

## Test Output Interpretation

### Success Indicators
- `PASS ✓` - Test passed successfully
- `OPEN` - Port is reachable
- `CONNECTION_SUCCESSFUL` - Database authentication successful
- `EXECUTED ✓` - InSpec control ran without errors

### Failure Indicators
- `FAIL ✗` - Test failed
- `CLOSED` - Port is not reachable
- Authentication error messages (ORA-01017, Login failed, etc.)
- InSpec exit code non-zero

## Troubleshooting

### SSH Connection Failed
```bash
# Check SSH key permissions
ls -la ~/.ssh/inspec_azure  # Should be 600

# Test SSH manually
ssh -o StrictHostKeyChecking=no -i ~/.ssh/inspec_azure \
  azureuser@40.114.45.75 "echo OK"
```

### Oracle Port Not Reachable
```bash
# Verify Oracle server is running (on runner)
curl -i http://10.0.2.5:1521  # Oracle should reject HTTP

# Check firewall rules
sudo iptables -L -n | grep 1521

# Restart Oracle listener
sqlplus / as sysdba
> lsnrctl status
```

### Oracle Authentication Failed
```bash
# Verify credentials are correct
# Check Oracle user exists:
sqlplus system/<password>@//10.0.2.5:1521/ORCLCDB
> SELECT USERNAME FROM dba_users WHERE USERNAME='SYSTEM';

# Common error codes:
# ORA-01017: invalid username/password
# ORA-12514: TNS listener does not currently know of service
# ORA-12541: TNS:no listener
```

### Sybase Port Not Reachable
```bash
# Verify Sybase server is running (on runner)
netstat -an | grep 5000  # Check if port is listening

# Verify FreeTDS configuration
cat /etc/freetds.conf | grep -A5 "10.0.2.6"

# Test FreeTDS directly
tsql -S 10.0.2.6 -U sa
```

### Sybase Authentication Failed
```bash
# Test with different user
tsql -S 10.0.2.6 -U sa -P <password>

# Check if password contains special characters
# If so, may need to escape or quote differently

# Common errors:
# Login failed - check username/password
# Server not found in /etc/freetds.conf
```

### InSpec Control Execution Failed
```bash
# Check InSpec installation
inspec --version

# Verify control syntax
inspec exec /tmp/oracle_test_control.rb -l  # Dry run

# Check environment variables
echo $ORACLE_HOME
echo $LD_LIBRARY_PATH
echo $PATH
```

## Environment Variables Used

### SSH/Runner Configuration
- `SSH_KEY` - Path to SSH private key (default: ~/.ssh/inspec_azure)
- `RUNNER_HOST` - Runner host IP address (default: 40.114.45.75)
- `RUNNER_USER` - Runner SSH username (default: azureuser)

### Oracle Configuration
- `ORACLE_SERVER` - Oracle server IP/hostname (default: 10.0.2.5)
- `ORACLE_PORT` - Oracle listener port (default: 1521)
- `ORACLE_SERVICE` - Oracle service name (default: ORCLCDB)
- `ORACLE_USERNAME` - Oracle username (default: system)
- `ORACLE_PASSWORD` - Oracle password (default: OraclePass123)

### Sybase Configuration
- `SYBASE_SERVER` - Sybase server IP/hostname (default: 10.0.2.6)
- `SYBASE_PORT` - Sybase port (default: 5000)
- `SYBASE_USERNAME` - Sybase username (default: sa)
- `SYBASE_PASSWORD` - Sybase password (default: SybasePass123)

## Advanced Testing

### Manual SSH Tunnel to Databases

#### Oracle via SSH Tunnel
```bash
# Create tunnel
ssh -L 1521:10.0.2.5:1521 -i ~/.ssh/inspec_azure azureuser@40.114.45.75 -N &

# Connect via local tunnel
sqlplus system/OraclePass123@//localhost:1521/ORCLCDB
```

#### Sybase via SSH Tunnel
```bash
# Create tunnel
ssh -L 5000:10.0.2.6:5000 -i ~/.ssh/inspec_azure azureuser@40.114.45.75 -N &

# Connect via local tunnel
tsql -S localhost -U sa -P SybasePass123
```

### Running Individual Tests

```bash
# Run only SSH test
ansible-playbook test_playbooks/test_oracle_sybase_connectivity.yml \
  --tags "TEST 1"

# Run only Oracle tests
ansible-playbook test_playbooks/test_oracle_sybase_connectivity.yml \
  --tags "TEST 2,TEST 3,TEST 6"

# Run only Sybase tests
ansible-playbook test_playbooks/test_oracle_sybase_connectivity.yml \
  --tags "TEST 4,TEST 5,TEST 7"
```

### Debug Output

```bash
# Enable Ansible verbose mode
ansible-playbook test_playbooks/test_oracle_sybase_connectivity.yml -vvv

# Capture detailed output to file
ansible-playbook test_playbooks/test_oracle_sybase_connectivity.yml \
  -vvv 2>&1 | tee test_output.log
```

## Next Steps

After successful connectivity testing:

1. **Review Role Implementation**
   - `roles/oracle_inspec/` - Oracle-specific role
   - `roles/sybase_inspec/` - Sybase-specific role

2. **Run Full InSpec Scanning Playbooks**
   ```bash
   # Oracle scanning
   ansible-playbook test_playbooks/run_oracle_inspec.yml

   # Sybase scanning
   ansible-playbook test_playbooks/run_sybase_inspec.yml
   ```

3. **Review Results**
   - Check `/tmp/inspec_oracle_results/` for Oracle results
   - Check `/tmp/inspec_sybase_results/` for Sybase results

4. **Inspect Result Files**
   ```bash
   # View results
   ls -la /tmp/inspec_*_results/
   cat /tmp/inspec_oracle_results/*.json | jq '.'
   cat /tmp/inspec_sybase_results/*.json | jq '.'
   ```

## Cleanup

To clean up test files and temporary resources:

```bash
# Clean up InSpec profile test files on runner
ssh -i ~/.ssh/inspec_azure azureuser@40.114.45.75 \
  "rm -f /tmp/oracle_test_control.rb /tmp/sybase_test_control.rb"

# Clean up results locally
rm -rf /tmp/inspec_*_results/
```

## Support and Issues

For issues or questions:

1. Check [TROUBLESHOOTING_GUIDE.md](../docs/TROUBLESHOOTING_GUIDE.md)
2. Review [DATABASE_COMPLIANCE_SCANNING_DESIGN.md](../docs/DATABASE_COMPLIANCE_SCANNING_DESIGN.md)
3. Check Ansible logs in `test_results/` directory
4. Consult database-specific documentation:
   - [Oracle SQL*Plus User Guide](https://docs.oracle.com/cd/E11882_01/server.112/e10592/toc.htm)
   - [Sybase isql Reference](https://infocenter.sybase.com/help/index.jsp)
   - [InSpec Documentation](https://docs.chef.io/inspec/)
