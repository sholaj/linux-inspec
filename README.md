# Database Compliance Scanning with Ansible and InSpec

Automated compliance scanning solution for MSSQL, Oracle, and Sybase databases using Ansible and InSpec. Supports multi-region architectures with jump servers and delegate execution patterns.

## Overview

This project provides production-ready Ansible roles and playbooks for executing compliance scans on database servers across multiple platforms. It implements delegate execution patterns to support:

- Single region deployments (direct connection)
- Multi-region deployments (with jump servers/bastions)
- Ansible Automation Platform (AAP) mesh architectures
- Non-interactive SSH sessions with proper environment variable loading

## Project Structure

```
.
├── ansible.cfg                    # Ansible configuration
├── inventories/                   # Inventory files by environment
│   ├── production/
│   │   └── hosts.yml             # Production database inventory
│   └── staging/
│       └── hosts.yml             # Staging/test database inventory
├── roles/                        # Ansible roles for database scanning
│   ├── mssql_inspec/            # MSSQL compliance scanning role
│   │   ├── defaults/            # Default variables
│   │   ├── tasks/               # Task files
│   │   ├── files/               # InSpec control files
│   │   └── templates/           # Report templates
│   ├── oracle_inspec/           # Oracle compliance scanning role
│   │   ├── defaults/
│   │   ├── tasks/
│   │   ├── files/
│   │   └── templates/
│   └── sybase_inspec/           # Sybase compliance scanning role
│       ├── defaults/
│       ├── tasks/
│       ├── files/
│       └── templates/
├── test_playbooks/              # Test and validation playbooks
│   ├── test_delegate_execution_flow.yml
│   ├── test_delegate_connection.yml
│   ├── test_mssql_implementation.yml
│   ├── run_compliance_scans.yml
│   ├── run_mssql_inspec.yml
│   ├── run_oracle_inspec.yml
│   └── run_sybase_inspec.yml
├── docs/                        # Documentation
├── scripts/                     # Utility scripts
├── convert_flatfile_to_inventory.py  # Inventory conversion tool
├── LICENSE
└── README.md                    # This file
```

## Features

### Multi-Platform Support
- **MSSQL**: Server-level compliance scanning (all databases on server)
- **Oracle**: Database-level compliance scanning
- **Sybase**: Database-level compliance scanning with SSH support

### Execution Patterns
- **Delegate Execution**: InSpec runs on delegate host, connects to databases remotely
- **Direct Execution**: InSpec runs locally (for testing)
- **Jump Server Support**: Transparent jump server/bastion integration

### Architecture Support
- Single region (no jump servers)
- Multi-region (with jump servers)
- AAP Automation Mesh
- Non-interactive SSH sessions with environment variable loading

### Enterprise Features
- Vault-encrypted credential management
- Splunk integration for results
- Batch execution with configurable concurrency
- Comprehensive error handling and reporting
- Check mode (dry-run) support
- Retry logic for transient failures

## Quick Start

### Prerequisites

1. **Ansible**: Version 2.9 or higher
   ```bash
   pip install ansible
   ```

2. **InSpec**: Installed on delegate host(s)
   ```bash
   curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
   ```

3. **Database Client Tools**: Installed on delegate host(s)
   - MSSQL: `sqlcmd` (MSSQL tools)
   - Oracle: `sqlplus` (Oracle client)
   - Sybase: `isql` (Sybase client)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd linux-inspec
   ```

2. Configure inventory:
   ```bash
   # Edit hosts.yml with your database server details
   vi inventories/production/hosts.yml
   ```

3. Set up vault for credentials:
   ```bash
   echo "your_vault_password" > .vaultpass
   chmod 600 .vaultpass
   ansible-vault create inventories/production/vault.yml
   ```

4. Add database credentials to vault:
   ```yaml
   ---
   vault_sqlserver01_password: "secure_password"
   vault_oracledb01_password: "secure_password"
   vault_sybasedb01_password: "secure_password"
   ```

### Running Tests

Before running production scans, validate your configuration:

1. **Test Delegate Execution Pattern**:
   ```bash
   ansible-playbook -i inventories/production test_playbooks/test_delegate_execution_flow.yml
   ```

2. **Test Connection Patterns**:
   ```bash
   ansible-playbook -i inventories/production test_playbooks/test_delegate_connection.yml
   ```

3. **Test MSSQL Implementation**:
   ```bash
   ansible-playbook -i inventories/production test_playbooks/test_mssql_implementation.yml --check
   ```

### Running Compliance Scans

#### All Platforms
```bash
ansible-playbook -i inventories/production test_playbooks/run_compliance_scans.yml \
  -e @inventories/production/vault.yml --vault-password-file .vaultpass
```

#### MSSQL Only
```bash
ansible-playbook -i inventories/production test_playbooks/run_mssql_inspec.yml \
  -e @inventories/production/vault.yml --vault-password-file .vaultpass
```

#### Oracle Only
```bash
ansible-playbook -i inventories/production test_playbooks/run_oracle_inspec.yml \
  -e @inventories/production/vault.yml --vault-password-file .vaultpass
```

#### Sybase Only
```bash
ansible-playbook -i inventories/production test_playbooks/run_sybase_inspec.yml \
  -e @inventories/production/vault.yml --vault-password-file .vaultpass
```

#### With Extra Options
```bash
# Limit to specific hosts
ansible-playbook -i inventories/production test_playbooks/run_compliance_scans.yml \
  --limit "sqlserver01" -e @inventories/production/vault.yml --vault-password-file .vaultpass

# Enable debug mode
ansible-playbook -i inventories/production test_playbooks/run_compliance_scans.yml \
  -e "enable_debug=true" -e @inventories/production/vault.yml --vault-password-file .vaultpass

# Custom batch size
ansible-playbook -i inventories/production test_playbooks/run_compliance_scans.yml \
  -e "batch_size=10" -e @inventories/production/vault.yml --vault-password-file .vaultpass

# Check mode (dry-run)
ansible-playbook -i inventories/production test_playbooks/run_compliance_scans.yml \
  --check -e @inventories/production/vault.yml --vault-password-file .vaultpass
```

## Configuration

### Inventory Configuration

Example inventory structure for mixed platforms:

```yaml
all:
  vars:
    base_results_dir: "/var/compliance_results"
    enable_debug: false

  children:
    delegate_hosts:
      hosts:
        inspec-delegate-host:
          ansible_host: delegate.example.com
          ansible_connection: ssh

    mssql_databases:
      vars:
        database_platform: "mssql"
        inspec_delegate_host: inspec-delegate-host
      hosts:
        sqlserver01:
          ansible_host: sqlserver01.example.com
          mssql_server: sqlserver01.example.com
          mssql_port: 1433
          mssql_version: "2019"
          mssql_username: nist_scan_user
          mssql_password: "{{ vault_sqlserver01_password }}"

    oracle_databases:
      vars:
        database_platform: "oracle"
        inspec_delegate_host: inspec-delegate-host
      hosts:
        oracledb01:
          ansible_host: oracledb01.example.com
          oracle_server: oracledb01.example.com
          oracle_port: 1521
          oracle_database: ORCL
          oracle_service: ORCL
          oracle_version: "19c"
          oracle_username: nist_scan_user
          oracle_password: "{{ vault_oracledb01_password }}"

    sybase_databases:
      vars:
        database_platform: "sybase"
        inspec_delegate_host: inspec-delegate-host
        sybase_use_ssh: true
      hosts:
        sybasedb01:
          ansible_host: sybasedb01.example.com
          sybase_server: sybasedb01.example.com
          sybase_port: 5000
          sybase_database: master
          sybase_version: "16"
          sybase_username: nist_scan_user
          sybase_password: "{{ vault_sybasedb01_password }}"
```

### Jump Server Configuration

For multi-region deployments with jump servers:

```yaml
# Option 1: Per-host configuration
sqlserver01:
  ansible_host: sqlserver01.example.com
  ansible_ssh_common_args: '-o ProxyJump=jumpserver.example.com'

# Option 2: Group-level configuration
mssql_databases:
  vars:
    ansible_ssh_common_args: '-o ProxyJump=jumpserver.example.com'
```

Or in `ansible.cfg`:
```ini
[ssh_connection]
ssh_args = -o ProxyJump=jumpserver.example.com -o StrictHostKeyChecking=no
```

### Environment Variables for Non-Interactive SSH

The roles handle environment variable loading for non-interactive SSH sessions automatically. If needed, customize in role defaults:

```yaml
# roles/mssql_inspec/defaults/main.yml
mssql_env:
  PATH: "/opt/mssql-tools/bin:/usr/local/bin:/usr/bin:/bin"
  LD_LIBRARY_PATH: "/opt/mssql-tools/lib"
```

## Ansible Automation Platform (AAP) Integration

### Setup in AAP

1. **Create Project**: Point to this Git repository
2. **Add Inventory**: Upload production inventory or sync from source
3. **Add Credentials**:
   - Machine credential (SSH)
   - Vault credential (for encrypted variables)
   - Optional: Splunk token credential

4. **Create Job Template**:
   - Name: "Database Compliance Scans"
   - Inventory: Production Databases
   - Project: This repository
   - Playbook: `test_playbooks/run_compliance_scans.yml`
   - Credentials: Machine + Vault
   - Extra Variables:
     ```yaml
     enable_debug: false
     batch_size: 5
     splunk_enabled: true
     splunk_hec_url: "https://splunk.example.com:8088"
     ```

5. **Schedule**: Configure regular scan schedule (e.g., weekly)

### AAP Mesh Architecture

The delegate execution pattern works seamlessly with AAP mesh:

- Controller nodes run the playbook
- Execution nodes (delegate hosts) run InSpec
- Database connections from execution nodes to database servers
- Results collected back to controller

## Troubleshooting

### Common Issues

1. **InSpec not found on delegate host**
   ```bash
   # Install InSpec on delegate host
   curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
   ```

2. **Database client tools not found**
   ```bash
   # MSSQL tools
   # Download from Microsoft and add to PATH

   # Oracle client
   export ORACLE_HOME=/opt/oracle/instantclient
   export PATH=$ORACLE_HOME:$PATH

   # Sybase tools
   export SYBASE=/opt/sybase
   export PATH=$SYBASE/OCS/bin:$PATH
   ```

3. **Environment variables not loading in SSH sessions**
   - The roles explicitly set PATH and LD_LIBRARY_PATH
   - Verify delegate host has tools in expected locations
   - Check role defaults and override if needed

4. **Jump server connection issues**
   - Verify SSH keys are configured for jump server
   - Test manually: `ssh -J jumpserver.com target.com`
   - Check `ansible_ssh_common_args` in inventory

5. **Delegation not working**
   - Ensure delegate host has `ansible_connection: ssh`
   - Verify `ansible_host` is set correctly
   - Run test playbook: `test_delegate_execution_flow.yml`

### Debug Mode

Enable verbose output:

```bash
# Playbook level
ansible-playbook ... -e "enable_debug=true"

# Ansible level
ansible-playbook ... -vvv
```

### Check Mode (Dry Run)

Validate without making changes:

```bash
ansible-playbook -i inventories/production test_playbooks/run_compliance_scans.yml --check
```

## Security

- **Never commit credentials**: Use Ansible Vault
- **Secure vault password file**: `chmod 600 .vaultpass`
- **Use SSH keys**: Avoid password authentication
- **Rotate credentials**: Regular credential rotation
- **Audit logs**: Review ansible.log regularly
- **Network security**: Use jump servers for multi-region
- **Principle of least privilege**: Use dedicated scan user accounts

## License

See LICENSE file for details.

## Support

For issues, questions, or contributions:
- Create GitHub issue
- Review documentation in `docs/` directory
- Check test validation reports

## Acknowledgments

- Based on NIST database compliance requirements
- Implements patterns from Ansible best practices
- InSpec framework by Chef/Progress
- AAP mesh architecture support

---

**Last Updated**: 2025-12-14
**Version**: 2.0.0
**Maintainer**: DevOps Team
