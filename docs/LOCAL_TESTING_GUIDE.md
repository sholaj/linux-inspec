# Local Testing Infrastructure - MacBook Setup

## Overview
This guide helps you set up local MSSQL databases on your MacBook using Docker to test the compliance scanning solution.

## Prerequisites
1. **Docker Desktop for Mac** - Download from https://www.docker.com/products/docker-desktop
2. **Homebrew** - Package manager for macOS
3. **InSpec** - Compliance automation framework

## Quick Setup

### 1. One-Command Setup
```bash
./test_local_setup.sh
```
This script will:
- Check Docker installation
- Start MSSQL containers (2017 & 2019)
- Create databases and scanning users
- Generate test inventory
- Check InSpec installation

### 2. Manual Installation (if needed)

#### Install InSpec
```bash
# Option 1: Via Homebrew (recommended)
brew install chef/chef/inspec

# Option 2: Direct download
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
```

#### Verify Installation
```bash
inspec --version
```

## Local Infrastructure

### MSSQL Containers
The setup creates two MSSQL Server containers:

**MSSQL 2019:**
- Container: `mssql2019_test`
- Host: `localhost`
- Port: `1433`
- Database: `TestDB2019`
- SA Password: `TestPassword123!`
- Scan User: `nist_scan_user` / `ScanPassword123!`

**MSSQL 2017:**
- Container: `mssql2017_test`
- Host: `localhost`
- Port: `1734` (mapped from 1433)
- Database: `TestDB2017`
- SA Password: `TestPassword456!`
- Scan User: `nist_scan_user` / `ScanPassword456!`

### Generated Files
- `local_databases.txt` - Flat file with connection details
- `local_inventory.yml` - Ansible inventory
- `local_vault.yml` - Unencrypted vault with passwords

## Testing the Solution

### 1. Start Infrastructure
```bash
./test_local_setup.sh
```

### 2. Pre-Flight Validation (NEW - Error Handling Improvements)
Before running the playbooks, the test playbooks now perform automatic pre-flight validation checks:

**MSSQL Pre-Flight Checks:**
```bash
# Automatically verified before execution:
# ✓ sqlcmd is available in PATH
# ✓ sqlcmd version can be retrieved
# ✓ mssql-tools package is correctly installed
which sqlcmd
sqlcmd -?
```

**Oracle Pre-Flight Checks:**
```bash
# Automatically verified before execution:
# ✓ SQL*Plus is available in PATH
# ✓ ORACLE_HOME is set correctly
# ✓ TNS_ADMIN configuration exists
which sqlplus
```

**Sybase Pre-Flight Checks:**
```bash
# Automatically verified before execution:
# ✓ isql is available in PATH
# ✓ Sybase environment variables are set
which isql
```

If any pre-flight check fails, the playbook will exit immediately with a clear error message indicating what tool is missing and how to install it.

### 3. Run Compliance Scans
```bash
# Test with local databases (MSSQL)
ansible-playbook -i local_inventory.yml run_mssql_inspec.yml -e @local_vault.yml

# Debug mode with execution details
ansible-playbook -i local_inventory.yml run_mssql_inspec.yml -e @local_vault.yml -e inspec_debug_mode=true -vv

# Test specific database
ansible-playbook -i local_inventory.yml run_mssql_inspec.yml -e @local_vault.yml --limit "localhost_TestDB2019_1433"

# Test Oracle
ansible-playbook run_oracle_inspec.yml -e @local_vault.yml

# Test Sybase
ansible-playbook run_sybase_inspec.yml -e @local_vault.yml
```

### 4. View Results
```bash
# Check results directory
ls -la /tmp/compliance_scans/

# View specific results
cat /tmp/compliance_scans/*/MSSQL_NIST_*_*.json

# View execution log with timestamps
cat /tmp/compliance_scans/*/execution_*.log
```

## Manual Testing Commands

### Connect to Databases
```bash
# MSSQL 2019
docker exec -it mssql2019_test /opt/mssql-tools/bin/sqlcmd -S localhost -U nist_scan_user -P 'ScanPassword123!'

# MSSQL 2017
docker exec -it mssql2017_test /opt/mssql-tools/bin/sqlcmd -S localhost -U nist_scan_user -P 'ScanPassword456!'
```

### Test InSpec Controls Manually
```bash
# Test a single control file
inspec exec mssql_inspec/files/MSSQL2019_ruby/trusted.rb \
  --input usernm=nist_scan_user passwd=ScanPassword123! hostnm=localhost port=1433 \
  --reporter=json-min --no-color
```

### Monitor Containers
```bash
# View container status
docker-compose ps

# View logs
docker-compose logs -f

# Check resource usage
docker stats
```

## Troubleshooting

### Common Issues

**1. Port Already in Use**
```bash
# Check what's using port 1433
lsof -i :1433

# Stop conflicting services
sudo launchctl unload -w /System/Library/LaunchDaemons/com.microsoft.sqlserver.plist
```

**2. Container Won't Start**
```bash
# Check Docker resources
docker system df

# Restart Docker Desktop
# Clean up old containers
docker system prune -a
```

**3. SQL Connection Failures**
```bash
# Test connection manually
docker exec -it mssql2019_test /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'TestPassword123!' -Q "SELECT 1"

# Check container health
docker-compose ps
```

**4. InSpec Not Found**
```bash
# Add to PATH if needed
export PATH="/opt/inspec/bin:$PATH"

# Or use full path
/opt/inspec/bin/inspec --version
```

**5. Pre-Flight Check Failures (NEW - Error Handling)**

**Missing sqlcmd:**
```bash
# Error message:
# CRITICAL ERROR: sqlcmd not found in PATH
# Installation fix for macOS:
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew install mssql-tools
```

**Missing SQL*Plus:**
```bash
# Error message:
# CRITICAL ERROR: SQL*Plus not found in PATH
# Installation fix:
# 1. Download from Oracle
# 2. Install Oracle Instant Client
# 3. Set ORACLE_HOME and PATH environment variables
```

**Missing isql:**
```bash
# Error message:
# CRITICAL ERROR: isql not found in PATH
# Installation fix:
# 1. Install Sybase ASE client tools
# 2. Set SYBASE environment variable
# 3. Add SYBASE/bin to PATH
```

**6. Database Connection Timeouts**

If you see errors like "Cannot connect to database", this is automatically captured by the roles:
- The task will NOT fail (connection errors are expected in scan output)
- The JSON results will include the connection error message
- Check the `results.json` file in `/tmp/compliance_scans/` for details
- The error is logged but treated as expected behavior (database unavailable)

```bash
# View connection error details
grep "Cannot connect" /tmp/compliance_scans/*/MSSQL_NIST_*.json
```

**7. InSpec Execution Failures**

If InSpec itself fails (not database connectivity):
- The task WILL fail with a clear error message
- Exit codes will be non-zero and not related to connection timeouts
- Examples: invalid control files, syntax errors, missing dependencies

```bash
# Task will stop with failure and show:
# CRITICAL ERROR: InSpec execution failed with exit code X
```

## Performance Considerations

### Resource Requirements
- **RAM**: 4GB minimum for both containers
- **Disk**: 2GB for container images and data
- **CPU**: 2 cores recommended

### Optimization
```bash
# Limit container resources
docker update --memory=2g --cpus=1 mssql2019_test
docker update --memory=2g --cpus=1 mssql2017_test
```

## Cleanup

### Complete Cleanup
```bash
./cleanup_test_infra.sh
```

### Manual Cleanup
```bash
# Stop containers
docker-compose down -v

# Remove test files
rm -f local_*.yml local_databases.txt

# Clean results
rm -rf /tmp/compliance_scans
```

## Integration with Main Solution

This local setup exactly mirrors the production workflow:

1. **Flat File Input** - Same 6-field format
2. **Inventory Generation** - Same conversion process
3. **Vault Management** - Same password structure
4. **Playbook Execution** - Same Ansible commands
5. **Results Format** - Same JSON output structure

The only differences are:
- Local Docker containers vs remote MSSQL servers
- Unencrypted vault vs encrypted vault
- Test passwords vs production credentials

## Enhanced Error Handling (NEW - Execution Architecture)

### Three-Layer Error Detection System

The roles now implement a sophisticated three-layer error detection system:

**Layer 1: Pre-Flight Validation**
- Happens BEFORE InSpec execution
- Validates required tools exist in PATH (sqlcmd, SQL*Plus, isql)
- Fails immediately with clear installation instructions
- Prevents silent failures from missing dependencies

**Layer 2: Execution Status Monitoring**
- Captures exit codes from InSpec execution
- Distinguishes between:
  - **Actual failures** (non-zero exit codes from tool/syntax errors) → Task FAILS
  - **Connection timeouts** (database unreachable) → Task PASSES, error in JSON output

**Layer 3: Results Processing**
- Parses JSON output from InSpec
- Captures both control results and connection errors
- Stores sanitized logs without passwords
- Generates execution summaries with timestamps

### Error Handling by Type

| Error Type | Detection | Behavior | Result |
|-----------|-----------|----------|--------|
| Missing sqlcmd/isql/SQL*Plus | Pre-flight check | Fails immediately | Clear install message |
| InSpec syntax error | Exit code != 0 | Task fails | Shows error in logs |
| Database connection timeout | stdout contains "Cannot connect" | Task passes | Error captured in JSON |
| Permission denied on files | Exit code != 0 | Task fails | Requires investigation |
| Invalid credentials | stdout contains "Cannot connect" | Task passes | Error in JSON output |

### How to Check Error Status

```bash
# View execution log to see what happened
cat /tmp/compliance_scans/*/execution_*.log

# Check JSON results for embedded connection errors
grep "Cannot\|connection\|Unreachable" /tmp/compliance_scans/*/*.json

# Run with debug mode to see detailed execution steps
ansible-playbook run_mssql_inspec.yml -e inspec_debug_mode=true -vv

# Test pre-flight checks in isolation
ansible-playbook -i local_inventory.yml test_mssql_localhost.yml --tags "preflight"
```

### Execution Target Control

All roles support flexible execution via the `inspec_execution_target` variable:

```bash
# Execute on localhost (default)
ansible-playbook run_mssql_inspec.yml

# Execute on delegate host (requires SSH setup)
ansible-playbook run_mssql_inspec.yml -e inspec_delegate_host=bastion.example.com

# Multiple databases with different targets
ansible-playbook run_mssql_inspec.yml -e inspec_delegate_host=prod-bastion -i production_inventory.yml
```

## Next Steps

After successful local testing:
1. Test with encrypted vault: `ansible-vault encrypt local_vault.yml`
2. Test with production-like credentials
3. Validate result forwarding to Splunk (if available)
4. Test with larger database inventories
5. Deploy to AAP environment
