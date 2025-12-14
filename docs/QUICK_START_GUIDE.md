# Quick Start Guide - Database Compliance Scanning

This guide will help you get started with the database compliance scanning project.

## Prerequisites Check

Before you begin, ensure you have:

1. **Ansible installed** (version 2.9+)
   ```bash
   ansible --version
   ```

2. **InSpec installed on delegate host**
   ```bash
   ssh delegate-host "inspec --version"
   ```

3. **Database client tools installed on delegate host**
   ```bash
   # MSSQL
   ssh delegate-host "command -v sqlcmd"
   
   # Oracle
   ssh delegate-host "command -v sqlplus"
   
   # Sybase
   ssh delegate-host "command -v isql"
   ```

## Step 1: Configure Your Environment

### 1.1 Update Production Inventory

Edit the production inventory with your database servers:

```bash
cd /Users/shola/Documents/MyGoProject/linux-inspec
vi inventories/production/hosts.yml
```

Add your database servers in the appropriate groups (mssql_databases, oracle_databases, sybase_databases).

### 1.2 Create Vault with Credentials

```bash
# Create vault password file
echo "your_secure_vault_password" > .vaultpass
chmod 600 .vaultpass

# Create encrypted vault file
ansible-vault create inventories/production/vault.yml --vault-password-file .vaultpass
```

Add your database credentials:

```yaml
---
# MSSQL passwords
vault_sqlserver01_password: "secure_password_here"

# Oracle passwords  
vault_oracledb01_password: "secure_password_here"

# Sybase passwords
vault_sybasedb01_password: "secure_password_here"
vault_sybasedb01_ssh_password: "ssh_password_here"
```

## Step 2: Validate Your Configuration

### 2.1 Test Delegate Execution Pattern

This validates that delegate execution works correctly:

```bash
ansible-playbook -i inventories/production \
  test_playbooks/test_delegate_execution_flow.yml
```

**Expected Result**: All tests should pass, showing delegation is working.

### 2.2 Test Connection Patterns

This validates different connection scenarios:

```bash
ansible-playbook -i inventories/production \
  test_playbooks/test_delegate_connection.yml
```

**Expected Result**: Connection tests pass for your environment (direct or jump server).

### 2.3 Dry Run of Compliance Scans

Test without actually executing:

```bash
ansible-playbook -i inventories/production \
  test_playbooks/run_compliance_scans.yml --check
```

**Expected Result**: No errors, playbook validates successfully.

## Step 3: Run Your First Scan

### 3.1 Test on Single Host

Start with a single database to verify everything works:

```bash
ansible-playbook -i inventories/production \
  test_playbooks/run_mssql_inspec.yml \
  --limit "sqlserver01" \
  -e @inventories/production/vault.yml \
  --vault-password-file .vaultpass
```

**Expected Result**: Scan completes successfully, results in base_results_dir.

### 3.2 Scan All MSSQL Servers

Once single host works, scan all MSSQL servers:

```bash
ansible-playbook -i inventories/production \
  test_playbooks/run_mssql_inspec.yml \
  -e @inventories/production/vault.yml \
  --vault-password-file .vaultpass
```

### 3.3 Scan All Database Platforms

Scan MSSQL, Oracle, and Sybase databases:

```bash
ansible-playbook -i inventories/production \
  test_playbooks/run_compliance_scans.yml \
  -e @inventories/production/vault.yml \
  --vault-password-file .vaultpass
```

## Step 4: Review Results

### 4.1 Check Scan Results

Results are stored in JSON format:

```bash
# List all results
find /var/compliance_results -name "*.json"

# View summary
ls -lh /var/compliance_results/

# Check MSSQL results
find /var/compliance_results -name "MSSQL_NIST_*.json"
```

### 4.2 Review Logs

Check Ansible logs for any issues:

```bash
tail -f logs/ansible.log
```

### 4.3 View Splunk (if configured)

If Splunk integration is enabled, check your Splunk instance for compliance events.

## Common Operations

### Scan Specific Platform

```bash
# MSSQL only
ansible-playbook -i inventories/production \
  test_playbooks/run_mssql_inspec.yml \
  -e @inventories/production/vault.yml \
  --vault-password-file .vaultpass

# Oracle only
ansible-playbook -i inventories/production \
  test_playbooks/run_oracle_inspec.yml \
  -e @inventories/production/vault.yml \
  --vault-password-file .vaultpass

# Sybase only
ansible-playbook -i inventories/production \
  test_playbooks/run_sybase_inspec.yml \
  -e @inventories/production/vault.yml \
  --vault-password-file .vaultpass
```

### Limit to Specific Hosts

```bash
# Single host
ansible-playbook ... --limit "sqlserver01"

# Multiple hosts
ansible-playbook ... --limit "sqlserver01,sqlserver02"

# All hosts matching pattern
ansible-playbook ... --limit "sqlserver*"
```

### Enable Debug Mode

```bash
ansible-playbook ... -e "enable_debug=true"
```

### Adjust Batch Size

```bash
# Scan 10 databases at a time instead of default 5
ansible-playbook ... -e "batch_size=10"
```

## Troubleshooting

### Issue: Delegation Not Working

**Symptoms**: Tests show delegation not working, tasks run on same host.

**Solution**:
1. Check delegate host has `ansible_connection: ssh` in inventory
2. Verify SSH connectivity: `ssh delegate-host`
3. Review inventory configuration
4. Run test again with `-vvv` for details

### Issue: InSpec Not Found

**Symptoms**: Test shows InSpec not found on delegate host.

**Solution**:
```bash
# Install InSpec on delegate host
ssh delegate-host
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
exit
```

### Issue: Database Client Tools Not Found

**Symptoms**: sqlcmd/sqlplus/isql not found.

**Solution**:
1. Install tools on delegate host
2. Add tools to PATH
3. Update role defaults if tools in non-standard location

### Issue: Connection Failures

**Symptoms**: Cannot connect to database.

**Solution**:
1. Verify database credentials in vault
2. Test connection from delegate host manually
3. Check network connectivity
4. Verify database user permissions

### Issue: Jump Server Issues

**Symptoms**: Cannot connect through jump server.

**Solution**:
1. Verify jump server configuration in inventory
2. Test manually: `ssh -J jumpserver database-host`
3. Check SSH keys configured for jump server
4. Review `ansible_ssh_common_args` setting

## Next Steps

1. **Schedule Regular Scans**
   - Set up cron job or AAP schedule
   - Weekly recommended for compliance

2. **Configure Splunk Integration**
   - Add Splunk variables to inventory
   - Enable `splunk_enabled: true`

3. **Set Up AAP (if using)**
   - Create project in AAP
   - Upload inventory
   - Configure credentials
   - Create job templates
   - Set up schedules

4. **Establish Monitoring**
   - Monitor logs for failures
   - Set up alerts for scan failures
   - Review compliance reports regularly

5. **Document Your Environment**
   - Document any customizations
   - Keep inventory up to date
   - Maintain runbooks for common issues

## Additional Resources

- **Main README**: `README.md`
- **DevOps Review**: `DEVOPS_REVIEW_AND_IMPROVEMENTS.md`
- **Implementation Summary**: `IMPLEMENTATION_SUMMARY.md`
- **Test Playbooks Guide**: `test_playbooks/README.md`
- **Documentation Directory**: `docs/`

## Getting Help

1. Review error messages carefully
2. Check logs in `logs/ansible.log`
3. Run with debug: `-e "enable_debug=true" -vvv`
4. Review test playbook output
5. Consult documentation in docs/ directory

---

**Quick Reference Commands**:

```bash
# Test delegate execution
ansible-playbook -i inventories/production test_playbooks/test_delegate_execution_flow.yml

# Test connections  
ansible-playbook -i inventories/production test_playbooks/test_delegate_connection.yml

# Scan all platforms
ansible-playbook -i inventories/production test_playbooks/run_compliance_scans.yml \
  -e @inventories/production/vault.yml --vault-password-file .vaultpass

# Scan MSSQL only
ansible-playbook -i inventories/production test_playbooks/run_mssql_inspec.yml \
  -e @inventories/production/vault.yml --vault-password-file .vaultpass

# Debug mode
ansible-playbook ... -e "enable_debug=true" -vvv

# Single host
ansible-playbook ... --limit "hostname"

# Check mode (dry run)
ansible-playbook ... --check
```

Good luck with your database compliance scanning!
