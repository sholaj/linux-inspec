# Database Flat File to Inventory Converter

Ansible-native converter for transforming database flat files into Ansible inventory and vault files.

## [DIR] Directory Structure

```
inventory_converter/
├── convert_flatfile_to_inventory.yml  # Main converter playbook
├── process_flatfile_line.yml          # Line processing logic
├── templates/
│   └── vault_template.j2              # Vault file template
└── README.md                           # This file
```

## [TARGET] Purpose

Converts a 6-field flat file format into:
- **Ansible inventory** with platform-specific groups
- **Vault file** with password placeholders

### Platform Support

- **MSSQL** - Server-level scanning (deduplicates by server:port)
- **Oracle** - Database-level scanning
- **Sybase** - Database-level scanning with SSH support

## [USAGE] Usage

### Basic Usage

```bash
cd inventory_converter
ansible-playbook convert_flatfile_to_inventory.yml
```

### Custom Parameters

```bash
ansible-playbook convert_flatfile_to_inventory.yml \
  -e "flatfile_input=../databases.txt" \
  -e "inventory_output=../inventory.yml" \
  -e "vault_output=../vault.yml"
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `flatfile_input` | `databases.txt` | Input flat file path |
| `inventory_output` | `inventory.yml` | Output inventory file path |
| `vault_output` | `vault.yml` | Output vault file path |
| `username` | `nist_scan_user` | Default database username |
| `create_vault` | `true` | Generate vault file |

## [FORMAT] Input Format

**6-field format (NO credentials):**
```
PLATFORM SERVER_NAME DB_NAME SERVICE_NAME PORT VERSION
```

### Examples

```
MSSQL testserver01 testdb01 TestService 1433 2019
ORACLE oracleserver01 orcl XE 1521 19c
SYBASE sybaseserver01 master SAP_ASE 5000 16
```

### MSSQL Special Behavior

Multiple MSSQL entries with the same `SERVER:PORT` are **deduplicated** into one host:

```
MSSQL server01 db1 svc1 1433 2019
MSSQL server01 db2 svc2 1433 2019
```
→ Results in **one** inventory host: `server01_1433`

## [OUTPUT] Output Structure

### Inventory File

```yaml
all:
  children:
    mssql_servers:      # Server-level (deduplicated)
      hosts:
        server_port:    # e.g., server01_1433
          mssql_server: server01
          mssql_port: 1433
          # ...
    oracle_databases:   # Database-level
      hosts:
        server_db_port: # e.g., oracleserver01_orcl_1521
          oracle_server: oracleserver01
          oracle_database: orcl
          # ...
    sybase_databases:   # Database-level
      hosts:
        server_db_port: # e.g., sybaseserver01_master_5000
          sybase_server: sybaseserver01
          sybase_database: master
          sybase_use_ssh: true
          # ...
```

### Vault File

```yaml
# MSSQL: vault_{server}_{port}_password
vault_server01_1433_password: DB_TEAM_TO_PROVIDE

# Oracle/Sybase: vault_{server}_{database}_{port}_password
vault_oracleserver01_orcl_1521_password: DB_TEAM_TO_PROVIDE
vault_sybaseserver01_master_5000_password: DB_TEAM_TO_PROVIDE

# Sybase SSH credentials
vault_sybase_ssh_password: DB_TEAM_TO_PROVIDE
vault_sybase_ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

## [TEST] Testing

```bash
# Create test flat file
cat > ../test_databases.txt <<EOF
MSSQL M010UB3 M010UB3 master 1733 2017
MSSQL M010UB3 M010UB3 MW 1733 2017
MSSQL CXP3W349 CXP3W349 FCSData 1433 2008R2
ORACLE oracleserver01 orcl XE 1521 19c
SYBASE sybaseserver01 master SAP_ASE 5000 16
EOF

# Run converter
ansible-playbook convert_flatfile_to_inventory.yml \
  -e "flatfile_input=../test_databases.txt" \
  -e "inventory_output=../test_inventory.yml" \
  -e "vault_output=../test_vault.yml"

# Verify inventory
ansible-inventory -i ../test_inventory.yml --graph
```

**Expected output**: 3 hosts (2 MSSQL servers deduplicated from 3 entries, 1 Oracle, 1 Sybase)

## [CONFIG] Integration

### With MSSQL Playbook

```bash
ansible-playbook -i inventory.yml ../run_mssql_inspec.yml -e @vault.yml
```

### With Multi-Platform Playbook

```bash
ansible-playbook -i inventory.yml ../run_compliance_scans.yml -e @vault.yml
```

## [DOCS] See Also

- [ANSIBLE_CONVERTER_IMPLEMENTATION.md](../ANSIBLE_CONVERTER_IMPLEMENTATION.md) - Detailed implementation docs
- [MULTI_PLATFORM_IMPLEMENTATION.md](../MULTI_PLATFORM_IMPLEMENTATION.md) - Multi-platform overview
- [run_mssql_inspec.yml](../run_mssql_inspec.yml) - MSSQL scanning playbook
- [run_oracle_inspec.yml](../run_oracle_inspec.yml) - Oracle scanning playbook
- [run_sybase_inspec.yml](../run_sybase_inspec.yml) - Sybase scanning playbook
