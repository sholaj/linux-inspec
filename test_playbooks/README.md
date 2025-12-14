# Test Playbooks Directory

This directory contains all test and execution playbooks for database compliance scanning.

## Test Playbooks

### test_delegate_execution_flow.yml
**Purpose**: Validates that delegate execution patterns work correctly for InSpec scans.

**What it tests**:
- Delegate host targeting
- SSH connectivity to delegate host
- Fact gathering from delegate host
- Environment variable construction
- Database client tool availability
- InSpec installation and accessibility

**When to run**:
- Before first production deployment
- After infrastructure changes
- When adding new delegate hosts
- To troubleshoot delegation issues

**Usage**:
```bash
ansible-playbook -i ../inventories/production test_delegate_execution_flow.yml
```

### test_delegate_connection.yml
**Purpose**: Tests various connection scenarios including direct, delegate, and jump server patterns.

**What it tests**:
- Direct connection to database hosts
- SSH from delegate to database hosts
- Delegate execution pattern (InSpec scan pattern)
- Jump server/bastion configuration
- Non-interactive SSH environment variable loading

**When to run**:
- When setting up new environments
- To validate jump server configuration
- To troubleshoot connection issues
- Before multi-region deployments

**Usage**:
```bash
ansible-playbook -i ../inventories/production test_delegate_connection.yml
```

### test_mssql_implementation.yml
**Purpose**: Comprehensive testing of MSSQL scanning implementation.

**What it tests**:
- MSSQL role execution
- Control file handling
- Result generation
- Error handling

**When to run**:
- After role modifications
- Before MSSQL production scans
- To validate MSSQL-specific features

**Usage**:
```bash
ansible-playbook -i ../inventories/production test_mssql_implementation.yml --check
```

## Execution Playbooks

### run_compliance_scans.yml
**Purpose**: Execute compliance scans across all database platforms (MSSQL, Oracle, Sybase).

**Features**:
- Multi-platform scanning
- Batch execution with configurable concurrency
- Splunk integration
- Comprehensive error handling
- Summary reporting

**Usage**:
```bash
# Scan all platforms
ansible-playbook -i ../inventories/production run_compliance_scans.yml \
  -e @../inventories/production/vault.yml --vault-password-file ../.vaultpass

# Scan specific platform
ansible-playbook -i ../inventories/production run_compliance_scans.yml \
  --limit "mssql_databases" -e @../inventories/production/vault.yml --vault-password-file ../.vaultpass

# Enable debug mode
ansible-playbook -i ../inventories/production run_compliance_scans.yml \
  -e "enable_debug=true" -e @../inventories/production/vault.yml --vault-password-file ../.vaultpass
```

### run_mssql_inspec.yml
**Purpose**: Execute InSpec compliance scans on MSSQL servers only.

**Scope**: Server-level scanning (all databases on each server).

**Usage**:
```bash
ansible-playbook -i ../inventories/production run_mssql_inspec.yml \
  -e @../inventories/production/vault.yml --vault-password-file ../.vaultpass
```

### run_oracle_inspec.yml
**Purpose**: Execute InSpec compliance scans on Oracle databases only.

**Scope**: Database-level scanning.

**Usage**:
```bash
ansible-playbook -i ../inventories/production run_oracle_inspec.yml \
  -e @../inventories/production/vault.yml --vault-password-file ../.vaultpass
```

### run_sybase_inspec.yml
**Purpose**: Execute InSpec compliance scans on Sybase databases only.

**Scope**: Database-level scanning with SSH tunnel support.

**Usage**:
```bash
ansible-playbook -i ../inventories/production run_sybase_inspec.yml \
  -e @../inventories/production/vault.yml --vault-password-file ../.vaultpass
```

## Inventory Files

### test_inventory.yml
Test inventory with sample database configurations.

### test_mssql_inventory.yml
MSSQL-specific test inventory.

## Common Options

### Check Mode (Dry Run)
```bash
ansible-playbook ... --check
```

### Limit to Specific Hosts
```bash
ansible-playbook ... --limit "sqlserver01"
```

### Verbose Output
```bash
ansible-playbook ... -vvv
```

### Custom Batch Size
```bash
ansible-playbook ... -e "batch_size=10"
```

### Enable Debug
```bash
ansible-playbook ... -e "enable_debug=true"
```

## Execution Order Recommendations

1. **First Time Setup**:
   ```bash
   # Test delegate execution
   ansible-playbook -i ../inventories/production test_delegate_execution_flow.yml

   # Test connections
   ansible-playbook -i ../inventories/production test_delegate_connection.yml

   # Dry run of compliance scans
   ansible-playbook -i ../inventories/production run_compliance_scans.yml --check

   # Execute on limited hosts
   ansible-playbook -i ../inventories/production run_compliance_scans.yml --limit "test_host"
   ```

2. **Production Execution**:
   ```bash
   # All platforms
   ansible-playbook -i ../inventories/production run_compliance_scans.yml \
     -e @../inventories/production/vault.yml --vault-password-file ../.vaultpass

   # Or specific platform
   ansible-playbook -i ../inventories/production run_mssql_inspec.yml \
     -e @../inventories/production/vault.yml --vault-password-file ../.vaultpass
   ```

## Troubleshooting

### Test Failed: Delegation Not Working
1. Check delegate host connectivity: `ansible -i ../inventories/production delegate_hosts -m ping`
2. Verify ansible_connection: ssh in inventory
3. Test SSH manually: `ssh delegate-host`
4. Review test output for specific error messages

### Test Failed: InSpec Not Found
1. Install InSpec on delegate host: `curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec`
2. Verify PATH includes InSpec location
3. Test manually: `ssh delegate-host "inspec --version"`

### Test Failed: Database Tools Not Found
1. Install appropriate database client tools on delegate host
2. Add tools to PATH in role defaults
3. Verify manually: `ssh delegate-host "command -v sqlcmd"`

### Scan Failed: Connection Issues
1. Enable debug mode: `-e "enable_debug=true"`
2. Increase verbosity: `-vvv`
3. Test individual host: `--limit "failing_host"`
4. Check vault passwords are correct
5. Verify database connectivity from delegate host

## Best Practices

1. **Always test before production**:
   - Run test playbooks first
   - Use --check mode
   - Test with --limit on single host

2. **Use vault for credentials**:
   - Never commit unencrypted passwords
   - Keep .vaultpass secure (chmod 600)
   - Rotate credentials regularly

3. **Monitor execution**:
   - Review logs in ../logs/ansible.log
   - Check Splunk dashboards if configured
   - Review result JSON files

4. **Handle failures gracefully**:
   - Use retry files for failed hosts
   - Investigate failures before retrying
   - Document workarounds

---

For more information, see the main README.md in the project root.
