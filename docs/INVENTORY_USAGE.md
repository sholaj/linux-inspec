# MSSQL InSpec Inventory-Based Scanning

## Overview

The refactored solution uses Ansible's inventory system where each database is treated as a unique host with its own credentials. This approach is more scalable and secure for managing many databases with unique authentication requirements.

## Key Changes

### Inventory Structure
- Each database is a **unique host** in the inventory
- Host names are auto-generated as: `{server}_{database}_{port}`
- Each host has its own connection parameters and credentials
- Supports grouping by platform (mssql_databases, oracle_databases, sybase_databases)

### Advantages
1. **Unique Credentials**: Each database can have different username/password
2. **Parallel Execution**: Use Ansible's `serial` and `strategy` for controlled parallel scanning
3. **Selective Scanning**: Use `--limit` to scan specific databases
4. **Vault Integration**: Per-database password encryption support
5. **Scalability**: Easily manage hundreds of databases

## Workflow

### 1. Convert Flat File to Inventory

```bash
# Generate sample flat file
./convert_flatfile_to_inventory.py --generate-sample databases.txt

# Convert to inventory with vault template
./convert_flatfile_to_inventory.py -i databases.txt -o inventory.yml --vault-template vault.yml
```

### 2. Secure Passwords (Optional)

```bash
# Edit vault file with actual passwords
vi vault.yml

# Encrypt the vault
ansible-vault encrypt vault.yml
```

### 3. Run Compliance Scans

```bash
# Scan all MSSQL databases
ansible-playbook -i inventory.yml run_mssql_inspec.yml

# Scan with encrypted passwords
ansible-playbook -i inventory.yml run_mssql_inspec.yml -e @vault.yml --ask-vault-pass

# Scan specific databases only
ansible-playbook -i inventory.yml run_mssql_inspec.yml --limit "sqlserver01_*"

# Control parallelism
ansible-playbook -i inventory.yml run_mssql_inspec.yml -e "batch_size=10"
```

## Flat File Format

```
PLATFORM SERVER_NAME DB_NAME SERVICE_NAME PORT VERSION [USERNAME] [PASSWORD]
```

Examples:
```
# Basic entry (uses default username, password via vault)
MSSQL server1.com db1 null 1433 2019

# With username (password via vault)
MSSQL server2.com db2 null 1433 2018 scan_user

# With username and password
MSSQL server3.com db3 SQLEXPRESS 1434 2016 admin_scan P@ssw0rd123
```

## Inventory Example

```yaml
all:
  children:
    mssql_databases:
      hosts:
        server1_com_db1_1433:
          mssql_server: server1.com
          mssql_port: 1433
          mssql_database: db1
          mssql_username: nist_scan_user
          mssql_password: "{{ vault_password_server1_com_db1_1433 }}"
          mssql_version: '2019'
```

## Security Best Practices

1. **Never commit passwords**: Use Ansible Vault or external secret management
2. **Unique service accounts**: Create database-specific scanning accounts
3. **Minimum privileges**: Grant only necessary read permissions
4. **Rotate credentials**: Regular password rotation for scanning accounts
5. **Audit logging**: Monitor scanning account activity

## Troubleshooting

### View specific host variables
```bash
ansible-inventory -i inventory.yml --host server1_com_db1_1433
```

### Test connection to specific database
```bash
ansible -i inventory.yml server1_com_db1_1433 -m debug -a "var=hostvars[inventory_hostname]"
```

### Debug mode for detailed output
```bash
ansible-playbook -i inventory.yml run_mssql_inspec.yml -e "inspec_debug_mode=true"
```